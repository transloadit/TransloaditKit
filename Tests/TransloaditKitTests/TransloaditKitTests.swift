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
        prepareAssemblyResponse(assembly: serverAssembly)
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
        func storeFile() throws -> URL {
            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let targetLocation = docDir.appendingPathComponent("myfile.txt")
            try data.write(to: targetLocation)
            return targetLocation
        }
        
        func storeTwoFiles() throws -> [URL] {
            let urls = try (0..<2).map { _ in
                try storeFile()
            }
            return urls
        }
        
        let files = try storeTwoFiles()

        let serverAssembly = Fixtures.makeAssembly()
        prepareAssemblyResponse(assembly: serverAssembly)
        prepareNetworkForSuccesfulUploads(url: serverAssembly.tusURL, data: data)
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
        XCTFail("Implement me")
    }
    
    func testMakeSureTUSIsntInitializedForOnlyAssemblies() {
    // TODO: Decide if we need this test. It's an optimization... but maybe we don't want to make sure the dir isn't created
        XCTFail("Implement me")
    }
    
    private func prepareAssemblyResponse(assembly: Assembly) {
        let url = URL(string: "https://api2.transloadit.com/assemblies")!
        MockURLProtocol.prepareResponse(for: url, method: "POST") { _ in
            MockURLProtocol.Response(status: 200, headers: [:], data: Fixtures.makeAssemblyResponse(assembly: assembly))
        }
    }
    
    private func prepareNetworkForSuccesfulUploads(url: URL, data: Data, lowerCasedKeysInResponses: Bool = false) {
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
                                   
}

func clearDocumentsDirectory() {
    let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    clearDirectory(dir: docDir)
}

func clearDirectory(dir: URL) {
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
