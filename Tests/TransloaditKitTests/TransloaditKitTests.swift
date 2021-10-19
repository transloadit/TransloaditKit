import XCTest
import TransloaditKit // ⚠️ WARNING: We are not performing a testable import here. We want to test the real public API. By doing so, we'll know very quicklly if the public API is broken. Which is very important to prevent.
import AVFoundation

final class TransloaditKitTests: XCTestCase {
    public var transloadit: Transloadit!
    
    let resizeStep = Step(name: "resize", robot: "/image/resize", options: ["width": 50,
                                                               "height": 75,
                                                               "resize_strategy": "fit",
                                                               "result": true])
    
    override func setUp() {
        super.setUp()
        
        let credentials = Transloadit.Credentials(key: "I am a key", secret: "I am a secret")
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession.init(configuration: configuration)
        
        transloadit = Transloadit(credentials: credentials, session: session)
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
    
    func testMakeSureTUSIsntInitializedForOnlyAssemblies() {
        XCTFail("Implement me")
    }
    
    private func prepareAssemblyResponse(assembly: Assembly) {
        MockURLProtocol.prepareResponse(for: "POST") { _ in
            MockURLProtocol.Response(status: 200, headers: [:], data: Fixtures.makeAssemblyResponse(assembly: assembly))
        }
    }
                                   
                                   
}
