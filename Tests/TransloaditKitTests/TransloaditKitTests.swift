import XCTest
import TransloaditKit // ⚠️ WARNING: We are not performing a testable import here. We want to test the real public API. By doing so, we'll know very quicklly if the public API is broken. Which is very important to prevent.
import AVFoundation

final class MockDelegate: TransloaditFileDelegate {
    struct Progress {
        let bytesUploaded: Int
        let totalBytes: Int
    }
    
    var finishedUploads = [Assembly]()
    var startedUploads = [Assembly]()
    var progressForUploads = [(Progress, Assembly)]()
    var totalProgress = [Progress]()
    var errors = [Error]()
    
    var finishUploadExpectation: XCTestExpectation?
    var startUploadExpectation: XCTestExpectation?
    var fileErrorExpectation: XCTestExpectation?

    
    func didFinishUpload(assembly: Assembly, client: Transloadit) {
        finishedUploads.append(assembly)
        finishUploadExpectation?.fulfill()
    }
    
    func didStartUpload(assembly: Assembly, client: Transloadit) {
        startedUploads.append(assembly)
        startUploadExpectation?.fulfill()
    }
    
    func progressFor(assembly: Assembly, bytesUploaded: Int, totalBytes: Int, client: Transloadit) {
        let progress = Progress(bytesUploaded: bytesUploaded, totalBytes: totalBytes)
        progressForUploads.append((progress, assembly))
    }
    
    func totalProgress(bytesUploaded: Int, totalBytes: Int, client: Transloadit) {
        let progress = Progress(bytesUploaded: bytesUploaded, totalBytes: totalBytes)
        totalProgress.append(progress)
    }
    
    func didError(error: Error, client: Transloadit) {
        errors.append(error)
        fileErrorExpectation?.fulfill()
    }
}

final class TransloaditKitTests: XCTestCase {
    public var transloadit: Transloadit!
    
    let resizeStep = Step(name: "resize", robot: "/image/resize", options: ["width": 50,
                                                                            "height": 75,
                                                                            "resize_strategy": "fit",
                                                                            "result": true])
    
    var data: Data!
    
    var fileDelegate: MockDelegate!
    
    override func setUp() {
        super.setUp()
        
        let credentials = Transloadit.Credentials(key: "I am a key", secret: "I am a secret")
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession.init(configuration: configuration)
        
        transloadit = Transloadit(credentials: credentials, session: session)
        fileDelegate = MockDelegate()
        transloadit.delegate = fileDelegate
        data = Data("Hello".utf8)
    }
    
    func testTransloaditDoesntPollIfAssemblyFails() throws {
        XCTFail("Implement me")
    }
    
    func testContinuingUploadsOnNewSession() throws {
        XCTFail("Implement me")
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
        let numFiles = 2
        let finishedUploadExpectation = self.expectation(description: "Finished file upload")
        finishedUploadExpectation.expectedFulfillmentCount = numFiles
        
        let startedUploadsExpectation = self.expectation(description: "Started uploads")
        startedUploadsExpectation.expectedFulfillmentCount = numFiles
        
        fileDelegate.finishUploadExpectation = finishedUploadExpectation
        fileDelegate.startUploadExpectation = startedUploadsExpectation
        
        let (files, serverAssembly) = try Network.prepareForUploadingFiles(data: data)
        
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
    
    func testCanCancelLocalUploads() throws {
//        transloadit.cancelUploadsFor(assembly.id)
        XCTFail("Implement me")
    }
   
    
    // MARK: - Polling
    
    private func prepareNetworkForStatusCheck(assemblyURL: URL, expectedStatus: AssemblyStatus.Status = .completed) {
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
                
    
    func poll(statusToTestAgainst: AssemblyStatus.Status) throws {
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
                    if status.status == statusToTestAgainst {
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
    
    // MARK: - Creating Assembly util
    
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

}
