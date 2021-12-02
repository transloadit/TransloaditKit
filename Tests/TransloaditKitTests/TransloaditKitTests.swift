import XCTest
import TransloaditKit // ⚠️ WARNING: We are not performing a testable import here. We want to test the real public API. By doing so, we'll know very quicklly if the public API is broken. Which is very important to prevent.
import AVFoundation

final class TransloaditKitTests: XCTestCase {
    public var transloadit: Transloadit!
    
    let resizeStep = Step(name: "resize", robot: "/image/resize", options: ["width": 50,
                                                                            "height": 75,
                                                                            "resize_strategy": "fit",
                                                                            "result": true])
    
    var data: Data!
    
    var fileDelegate: TransloadItMockDelegate!
    
    override func setUp() {
        super.setUp()
        
        transloadit = makeClient()
        do {
            try transloadit.reset()
        } catch {
            XCTFail("Could not reset transloadit \(error)")
        }
        fileDelegate = TransloadItMockDelegate()
        transloadit.fileDelegate = fileDelegate
        data = Data("Hello".utf8)
    }
    
    override func tearDown() {
        transloadit.fileDelegate = nil
    }
    
    private func makeClient() -> Transloadit {
        let credentials = Transloadit.Credentials(key: "I am a key", secret: "I am a secret")
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession.init(configuration: configuration)
        
        return Transloadit(credentials: credentials, session: session)
    }
    
    // MARK: - File uploading
    
    func testCreateAssembly_Without_Uploading() throws {
        let serverAssembly = Fixtures.makeAssembly()
        Network.prepareAssemblyResponse(assembly: serverAssembly)
        let serverFinishedExpectation = expectation(description: "Waiting for createAssembly to be called")
        transloadit.createAssembly(steps: [resizeStep]) { result in
            switch result {
            case .success:
                serverFinishedExpectation.fulfill()
            case .failure:
                XCTFail("Creating an assembly should have succeeded")
            }
        }
        
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testCreatingAssembly_And_Uploading_Of_Files() throws {
        let (files, serverAssembly) = try Network.prepareForUploadingFiles(data: data)
        let numFiles = files.count
        let finishedUploadExpectation = self.expectation(description: "Finished file upload")
        finishedUploadExpectation.expectedFulfillmentCount = numFiles
        
        let startedUploadsExpectation = self.expectation(description: "Started uploads")
        startedUploadsExpectation.expectedFulfillmentCount = numFiles
        
        fileDelegate.finishUploadExpectation = finishedUploadExpectation
        fileDelegate.startUploadExpectation = startedUploadsExpectation
        
        createAssembly(files, completed: { result in
            
            switch result {
            case .success(let receivedAssembly):
                XCTAssertEqual(serverAssembly, receivedAssembly)
            case .failure:
                XCTFail("Expected call to succeed")
            }
        })
        
        wait(for: [startedUploadsExpectation, finishedUploadExpectation], timeout: 3)
        
        XCTAssertEqual(numFiles, fileDelegate.finishedUploads.count)
        XCTAssertEqual(numFiles, fileDelegate.startedUploads.count)
    }
    
    func testCanReset() throws {
        // Preparation
        let (files, _) = try Network.prepareForUploadingFiles(data: data)
        
        let finishedUploadExpectation = self.expectation(description: "Finished file upload")
        finishedUploadExpectation.isInverted = true
        fileDelegate.finishUploadExpectation = finishedUploadExpectation
        
        // Start
        createAssembly(files)
        try transloadit.reset()
        
        wait(for: [finishedUploadExpectation], timeout: 3)
        
        XCTAssertEqual(0, fileDelegate.finishedUploads.count)
    }
    
    func testStatusFetching() throws {
        let (_, serverAssembly) = try Network.prepareForUploadingFiles(data: data)
        prepareNetworkForStatusCheck(assemblyURL: serverAssembly.url, expectedStatus: .uploading)
        let serverExpectation = self.expectation(description: "Expected server to respond with a success")
        transloadit.fetchStatus(assemblyURL: serverAssembly.url, completion: { result in
            switch result {
            case .success:
                serverExpectation.fulfill()
            case .failure:
                XCTFail("The status-check returned an error against expectations")
            }
        })
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    // MARK: - Restoring upload sessions
    
    func testContinuingUploadsAfterStopping() throws {
        // Stop uploads, resume them with the same client. Make sure uploads are finished.
        let (files, _) = try Network.prepareForUploadingFiles(data: data)
        Network.prepareForStatusResponse(data: data) // Because TUS will perform a status check after continuing.
        let numFiles = files.count
        
        let startedUploadsExpectation = self.expectation(description: "Started uploads")
        startedUploadsExpectation.expectedFulfillmentCount = numFiles
        let finishedUploadExpectation = self.expectation(description: "Finished file upload")
        finishedUploadExpectation.expectedFulfillmentCount = numFiles
        
        fileDelegate.startUploadExpectation = startedUploadsExpectation
        
        var localAssembly: Assembly!
        transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { result in
            
            switch result {
            case .success(let assembly):
                localAssembly = assembly
            case .failure:
                XCTFail("Expected assembly creation to succeed.")
            }
        })
        
        wait(for: [startedUploadsExpectation], timeout: 3)
        
        transloadit.stopRunningUploads()
        
        // Restart uploads, continue where left off
        
        fileDelegate.finishUploadExpectation = finishedUploadExpectation
        transloadit.start()
        
        wait(for: [finishedUploadExpectation], timeout: 5)
        
        XCTAssert(fileDelegate.finishedUploads.contains(localAssembly))
    }
    
    func testContinuingUploadsOnNewSession() throws {
        // Stop uploads, resume them with a new client. Make sure uploads are finished.
        let (files, _) = try Network.prepareForUploadingFiles(data: data)
        Network.prepareForStatusResponse(data: data) // Because TUS will perform a status check after continuing.
        let numFiles = files.count
        
        let startedUploadsExpectation = self.expectation(description: "Started uploads")
        startedUploadsExpectation.expectedFulfillmentCount = numFiles
        fileDelegate.startUploadExpectation = startedUploadsExpectation
        
        var localAssembly: Assembly!
        transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { result in
            
            switch result {
            case .success(let assembly):
                localAssembly = assembly
            case .failure:
                XCTFail("Expected assembly creation to succeed.")
            }
        })
        
        wait(for: [startedUploadsExpectation], timeout: 3)
        
        transloadit.stopRunningUploads()
        
        // Restart uploads from new client, continue where left off
        
        let secondTransloadit = makeClient()
        let secondFileDelegate = TransloadItMockDelegate()
        
        secondTransloadit.fileDelegate = secondFileDelegate
        secondFileDelegate.name = "SECOND"
        
        let finishedUploadExpectation = self.expectation(description: "Finished file upload")
        finishedUploadExpectation.expectedFulfillmentCount = numFiles
        
        secondFileDelegate.finishUploadExpectation = finishedUploadExpectation
        secondTransloadit.start()
        
        wait(for: [finishedUploadExpectation], timeout: 5)
        
        XCTAssert(secondFileDelegate.finishedUploads.contains(localAssembly))
    }
    
    
    // MARK: - Polling
    
    func testPolling() throws {
        try poll(statusToTestAgainst: .completed)
    }
    
    func testPollingStopsOnCancelState() throws {
        // It's one thing if polling stops when status is completed. But it needs to stop polling on errors and canceled actions
        try poll(statusToTestAgainst: .canceled)
    }
    
    func testPollingStopsOnAbortedState() throws {
        // It's one thing if polling stops when status is completed. But it needs to stop polling on errors and canceled actions
        try poll(statusToTestAgainst: .aborted)
    }
    
    func testTransloaditDoesntPollIfAssemblyFails() throws {
        let (files, _) = try Network.prepareForUploadingFiles(data: data)
        Network.prepareForFailingAssemblyResponse()
        let serverFinishedExpectation = expectation(description: "Waiting for createAssembly to be called")
        let poller = transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { result in
            switch result {
            case .success:
                XCTFail("Expected server to fail for this test")
            case .failure:
                serverFinishedExpectation.fulfill()
            }
        })
        
        wait(for: [serverFinishedExpectation], timeout: 3)
        
        // Now let's check polling
        let pollerResponseThatShouldNotBeCalled = self.expectation(description: "Poller is called, but shouldn't have been called.")
        pollerResponseThatShouldNotBeCalled.isInverted  = true
        poller.pollAssemblyStatus { result in
            pollerResponseThatShouldNotBeCalled.fulfill()
        }
        
        let defaultPollingTime: Double = 3
        waitForExpectations(timeout: defaultPollingTime + 1, handler: nil)
    }
    
    private func poll(statusToTestAgainst: AssemblyStatus.ProcessingStatus) throws {
        let defaultPollingTime: Double = 3
        let pollingExpectation = expectation(description: "Waiting for polling to be called twice")
        pollingExpectation.expectedFulfillmentCount = 2 // The amount of calls required before a status check is finished (e.g. status is set to completed/canceled/aborted)
        let pollingStatusCompleteExpectation = expectation(description: "Waiting for polling status to be complete")
        
        let noMoreCallsExpectation = expectation(description: "This shouldn't be called")
        noMoreCallsExpectation.isInverted = true
        
        let (files, serverAssembly) = try Network.prepareForUploadingFiles(data: data)
        
        prepareNetworkForStatusCheck(assemblyURL: serverAssembly.url, expectedStatus: statusToTestAgainst)
        
        var isStatusCanceled = false
        
        createAssembly(files)
            .pollAssemblyStatus { result in
                
                pollingExpectation.fulfill()
                
                switch result {
                case .success(let status):
                    if status.processingStatus == statusToTestAgainst {
                        pollingStatusCompleteExpectation.fulfill()
                        // Now make sure that canceled isn't called any more
                        if isStatusCanceled {
                            noMoreCallsExpectation.fulfill()
                        }
                        isStatusCanceled = true
                    }
                case .failure(let error):
                    XCTFail("Polling threw error \(error)")
                }
            }
        
        wait(for: [pollingExpectation, pollingStatusCompleteExpectation], timeout:  defaultPollingTime * 2 + 1)
        
        // We wait to make sure polling doesnt keep calling
        wait(for: [noMoreCallsExpectation], timeout: defaultPollingTime * 3)
    }
    
    func testPollingSameFilesMultipleTimesShouldNotBreak() throws {
        // Here we are trying to break the thing.
        try testPolling()
        try testPolling()
    }
    
    // MARK: - Utils
    
    @discardableResult
    private func createAssembly(_ files: [URL]) -> TransloaditPoller {
        return createAssembly(files, completed: { _ in })
    }
    
    @discardableResult
    private func createAssembly(_ files: [URL], completed: @escaping (Result<Assembly, TransloaditError>) -> Void) -> TransloaditPoller {
        let serverFinishedExpectation = expectation(description: "Waiting for createAssembly to be called")
        let poller = transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { result in
            serverFinishedExpectation.fulfill()
            
            completed(result)
        })
        
        wait(for: [serverFinishedExpectation], timeout: 3)
        return poller
    }
    
    private func prepareNetworkForStatusCheck(assemblyURL: URL, expectedStatus: AssemblyStatus.ProcessingStatus = .completed) {
        var count = 1
        Network.prepareForStatusChecks(assemblyURL: assemblyURL) {
            if count == 0 {
                return Fixtures.makeAssemblyStatus(status: expectedStatus)
            } else {
                count -= 1
                return Fixtures.makeAssemblyStatus(status: .uploading)
            }
        }
        
    }
    
    
}

enum Files {
    
    static func clearDocumentsDirectory() {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        clearDirectory(dir: docDir)
    }
    
    static func clearDirectory(dir: URL) {
        do {
            let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            for name in names
            {
                let path = "\(dir.path)/\(name)"
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func storeFile(data: Data) throws -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let targetLocation = docDir.appendingPathComponent("myfile.txt")
        try data.write(to: targetLocation)
        return targetLocation
    }
    
    static func storeFiles(data: Data, _ amount: Int = 2) throws -> [URL] {
        let urls = try (0..<amount).map { _ in
            try storeFile(data: data)
        }
        return urls
    }
    
}

enum Network {
    
    @discardableResult
    static func prepareForUploadingFiles(data: Data) throws -> ([URL], Assembly) {
        let files = try Files.storeFiles(data: data, 2)
        
        let serverAssembly = Fixtures.makeAssembly()
        Network.prepareAssemblyResponse(assembly: serverAssembly)
        Network.prepareForSuccesfulUploads(url: serverAssembly.tusURL, data: data)
        
        return (files, serverAssembly)
    }
    
    static func prepareAssemblyResponse(assembly: Assembly) {
        let url = URL(string: "https://api2.transloadit.com/assemblies")!
        MockURLProtocol.prepareResponse(for: url, method: "POST") { _ in
            MockURLProtocol.Response(status: 200, headers: [:], data: Fixtures.makeAssemblyResponse(assembly: assembly))
        }
    }
    
    static func prepareForStatusResponse(data: Data) {
        let url = URL(string: "www.tus-image-upload-location-returned-for-creation-post.com")!
        MockURLProtocol.prepareResponse(for: url, method: "HEAD") { _ in
            MockURLProtocol.Response(status: 200, headers: ["Upload-Length": String(data.count),
                                                            "Upload-Offset": "0"], data: nil)
        }
    }
    
    static func prepareForFailingAssemblyResponse() {
        let url = URL(string: "https://api2.transloadit.com/assemblies")!
        MockURLProtocol.prepareResponse(for: url, method: "POST") { _ in
            MockURLProtocol.Response(status: 400, headers: [:], data: nil)
        }
    }
    
    static func prepareForSuccesfulUploads(url: URL, data: Data, lowerCasedKeysInResponses: Bool = false) {
        let uploadURL = URL(string: "www.tus-image-upload-location-returned-for-creation-post.com")!
        MockURLProtocol.prepareResponse(for: url, method: "POST") { _ in
            let key: String
            if lowerCasedKeysInResponses {
                key = "location"
            } else {
                key = "Location"
            }
            return MockURLProtocol.Response(status: 200, headers: [key: uploadURL.absoluteString], data: nil)
        }
        
        // Mimick chunk uploading with offsets
        MockURLProtocol.prepareResponse(for: uploadURL, method: "PATCH") { headers in
            sleep(1) // Upload delay
            guard let headers = headers,
                  let strOffset = headers["Upload-Offset"],
                  let offset = Int(strOffset),
                  let strContentLength = headers["Content-Length"],
                  let contentLength = Int(strContentLength) else {
                      let error = "Did not receive expected Upload-Offset and Content-Length in headers"
                      XCTFail(error)
                      fatalError(error)
                  }
            
            let newOffset = offset + contentLength
            
            let key: String
            if lowerCasedKeysInResponses {
                key = "upload-offset"
            } else {
                key = "Upload-Offset"
            }
            return MockURLProtocol.Response(status: 200, headers: [key: String(newOffset)], data: nil)
        }
        
    }
    
    static func prepareForStatusChecks(assemblyURL statusURL: URL, status: @escaping () -> AssemblyStatus) {
        
        MockURLProtocol.prepareResponse(for: statusURL, method: "GET") { _ in
            let assemblyStatus: AssemblyStatus = status()
            let response = Fixtures.makeAssemblyStatusResponse(assemblyStatus: assemblyStatus)
            
            
            return MockURLProtocol.Response(status: 200, headers: [:], data: response)
        }
    }
    
    static func prepareForStatusCheckFailingOnce(assemblyURL: URL, expectedStatus: AssemblyStatus.ProcessingStatus = .completed) {
        var count = 1
        Network.prepareForStatusChecks(assemblyURL: assemblyURL) {
            if count == 0 {
                return Fixtures.makeAssemblyStatus(status: expectedStatus)
            } else {
                count -= 1
                return Fixtures.makeAssemblyStatus(status: .uploading)
            }
        }
        
    }
}
