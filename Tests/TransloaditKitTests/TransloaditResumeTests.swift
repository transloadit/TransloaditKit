import XCTest
import TransloaditKit // ⚠️ WARNING: We are not performing a testable import here. We want to test the real public API. By doing so, we'll know very quicklly if the public API is broken. Which is very important to prevent.
import AVFoundation

final class TransloaditKitResumeTests: XCTestCase {
    var transloadit: Transloadit!
    
    let resizeStep = Step(name: "resize", robot: "/image/resize", options: ["width": 50,
                                                                            "height": 75,
                                                                            "resize_strategy": "fit",
                                                                            "result": true])
    
    var data: Data!
    
    var fileDelegate: TransloadItMockDelegate!
    
    override func setUp() {
        super.setUp()
        
        transloadit = makeClient()
        // We don't reset here to resume uploads
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
    
    func testContinuingUploadsOnNewSession() throws {
        // Stop uploads, resume them with a new client. Make sure uploads are finished.
        let (files, _) = try Network.prepareForUploadingFiles(data: data)
        Network.prepareForStatusResponse(data: data) // Because TUS will perform a status check after continuing.
        let numFiles = files.count
        
        let startedUploadsExpectation = self.expectation(description: "Started uploads")
        startedUploadsExpectation.expectedFulfillmentCount = numFiles
        fileDelegate.startUploadExpectation = startedUploadsExpectation
        
        transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { result in
            switch result {
            case .success: break
            case .failure:
                XCTFail("Expected assembly creation to succeed.")
            }
        })
        
        wait(for: [startedUploadsExpectation], timeout: 3)
    }
    
    func testTransloaditForwardsAssembliesOnStart() throws {
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
        
        wait(for: [startedUploadsExpectation], timeout: 5)
        
        let secondTransloadit = makeClient()
        let secondFileDelegate = TransloadItMockDelegate()
        
        secondTransloadit.fileDelegate = secondFileDelegate
        secondFileDelegate.name = "SECOND"
        
        let assemblies = secondTransloadit.start()
        XCTAssert(assemblies.map { $0.id }.contains(localAssembly.id), "Expected transloadit to give the assembly back of an assembly that's not yet uploaded.")
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
    
    
    
}
