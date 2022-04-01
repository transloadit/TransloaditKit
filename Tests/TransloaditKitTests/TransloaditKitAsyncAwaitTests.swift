#if compiler(>=5.5) && canImport(_Concurrency)
import Foundation
import XCTest
import TransloaditKit // ⚠️ WARNING: We are not performing a testable import here. We want to test the real public API. By doing so, we'll know very quicklly if the public API is broken. Which is very important to prevent.
import AVFoundation

// These tests are checking the async await public API of Transloadit

@available(macOS 12.0, iOS 13, *)
final class TransloaditKitAsyncAwaitTests: XCTestCase {
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
            // If there is no cache to delete, that's okay.
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
    
    func testCreatingAssemblyWithoutUploading() async throws {
        let serverAssembly = Fixtures.makeAssembly()
        Network.prepareAssemblyResponse(assembly: serverAssembly)
        let assembly = try await transloadit.createAssembly(steps: [resizeStep])
        XCTAssertEqual(assembly, serverAssembly)
    }
    
    func testCreatingAssemblyWithUploading() async throws {
        let serverAssembly = Fixtures.makeAssembly()
        Network.prepareAssemblyResponse(assembly: serverAssembly)
        let (files, _) = try Network.prepareForUploadingFiles(data: data)
        Network.prepareNetworkForStatusCheck(assemblyURL: serverAssembly.url, expectedStatus: .completed)

        let (assembly, poller) = try await transloadit.createAssembly(steps: [resizeStep], andUpload: files)
        
        XCTAssertEqual(assembly, serverAssembly)
        
        try await poller.waitForProcessing()
    }

}
#endif
