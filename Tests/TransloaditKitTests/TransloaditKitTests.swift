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
    
    override func setUp() {
        super.setUp()
        
        let credentials = Transloadit.Credentials(key: "I am a key", secret: "I am a secret")
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession.init(configuration: configuration)
        
        transloadit = Transloadit(credentials: credentials, session: session)
        data = Data("Hello".utf8)
        //        prepareNetworkForSuccesfulUploads(data: data)
    }
    
    func testCreateAssembly() {
        let serverAssembly = Fixtures.makeAssembly()
        Network.prepareAssemblyResponse(assembly: serverAssembly)
        let serverFinishedExpectation = expectation(description: "Waiting for createAssembly to be called")
        transloadit.createAssembly(steps: [resizeStep], completion: { result in
            switch result {
            case .success(let receivedAssembly):
                XCTAssertEqual(serverAssembly, receivedAssembly)
            case .failure:
                XCTFail("Expected call to succeed")
            }
            
            serverFinishedExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testCreateAssembly_and_UploadFile() throws {
        let (files, serverAssembly) = try Network.prepareForUploadingFiles(data: data)
        let serverFinishedExpectation = expectation(description: "Waiting for createAssembly to be called")
        transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { result in
            switch result {
            case .success(let receivedAssembly):
                XCTAssertEqual(serverAssembly, receivedAssembly)
            case .failure:
                XCTFail("Expected call to succeed")
            }
            
            serverFinishedExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testPolling() throws {
        
        let retryCount = 1
        let serverFinishedExpectation = expectation(description: "Waiting for createAssembly to be called")
        let pollingExpectation = expectation(description: "Waiting for polling to be called")
        pollingExpectation.expectedFulfillmentCount = retryCount + 1// preparing status gives two calls
        let pollingStatusCompleteExpectation = expectation(description: "Waiting for polling status to be complete")
        
        let (files, serverAssembly) = try Network.prepareForUploadingFiles(data: data)
        
        var count = retryCount
        Network.prepareForStatusChecks(assembly: serverAssembly) {
            if count == 0 {
                return Fixtures.makeAssemblyStatus(status: .completed)
            } else {
                count -= 1
                return Fixtures.makeAssemblyStatus(status: .uploading)
            }
        }
      
        transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { result in
            switch result {
            case .success(let receivedAssembly):
                XCTAssertEqual(serverAssembly, receivedAssembly)
            case .failure:
                XCTFail("Expected call to succeed")
            }
            
            serverFinishedExpectation.fulfill()
        }).pollAssemblyStatus { result in
            pollingExpectation.fulfill()
            
            switch result {
            case .success(let status):
                if status.status == .completed {
                    pollingStatusCompleteExpectation.fulfill()
                }
            case .failure(let error):
                XCTFail("Polling threw error \(error)")
            }
        }
        
        waitForExpectations(timeout: 8, handler: nil) // larger timeout time because of polling
    }
    
    func testPollingStopsOnCancel() throws {
        let expectedPollCounts = 2
        var count = expectedPollCounts - 1
        
        try poll(expectedPollCount: expectedPollCounts, statusToTestAgainst: .canceled, status: {
            if count == 0 {
                return Fixtures.makeAssemblyStatus(status: .canceled)
            } else {
                count -= 1
                return Fixtures.makeAssemblyStatus(status: .uploading)
            }
        })
    }
    
    func testPollingStopsOnAborted() throws {
        let expectedPollCounts = 2
        var count = expectedPollCounts - 1
        
        try poll(expectedPollCount: expectedPollCounts, statusToTestAgainst: .aborted, status: {
            if count == 0 {
                return Fixtures.makeAssemblyStatus(status: .aborted)
            } else {
                count -= 1
                return Fixtures.makeAssemblyStatus(status: .uploading)
            }
        })
    }
    
    func poll(expectedPollCount: Int, statusToTestAgainst: AssemblyStatus.Status, status: @escaping () -> AssemblyStatus) throws {
        // It's one thing if polling stops when status is completed. But it needs to stop polling on errors and canceled actions
        let serverFinishedExpectation = expectation(description: "Waiting for createAssembly to be called")
        let pollingExpectation = expectation(description: "Waiting for polling to be called")
        pollingExpectation.expectedFulfillmentCount = expectedPollCount
        let pollingStatusCompleteExpectation = expectation(description: "Waiting for polling status to be complete")
        
        let noMoreCallsExpectation = expectation(description: "This shouldn't be called")
        noMoreCallsExpectation.isInverted = true
        
        let (files, serverAssembly) = try Network.prepareForUploadingFiles(data: data)
        
        Network.prepareForStatusChecks(assembly: serverAssembly, status: status)
        
        var isStatusCanceled = false
        
        transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { result in
            switch result {
            case .success(let receivedAssembly):
                XCTAssertEqual(serverAssembly, receivedAssembly)
            case .failure:
                XCTFail("Expected call to succeed")
            }
            
            serverFinishedExpectation.fulfill()
        }).pollAssemblyStatus { result in
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
        
        wait(for: [serverFinishedExpectation, pollingExpectation, pollingStatusCompleteExpectation], timeout:  3)
        
        // We wait to make sure polling doesnt keep calling
        wait(for: [noMoreCallsExpectation], timeout: 9)
    }
    
    func testPollingSameFilesMultipleTimesShouldNotBreak() throws {
        // Here we are trying to break the thing.
        try testPolling()
        try testPolling()
    }
    
    func testMakeSureTUSIsntInitializedForOnlyAssemblies() {
        // TODO: Decide if we need this test. It's an optimization... but maybe we don't want to make sure the dir isn't created
        XCTFail("Implement me")
    }
        
    func testStatusUploadingOfFiles() throws {
        // TODO: Test delegate
        XCTFail("Implement me")
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
    
    static func prepareForStatusChecks(assembly: Assembly, status: @escaping () -> AssemblyStatus) {
        let statusURL = assembly.url
        
        MockURLProtocol.prepareResponse(for: statusURL, method: "GET") { _ in
            let assemblyStatus: AssemblyStatus = status()
            let response = Fixtures.makeAssemblyStatusResponse(assemblyStatus: assemblyStatus)
            

            return MockURLProtocol.Response(status: 200, headers: [:], data: response)
        }
    }

}
