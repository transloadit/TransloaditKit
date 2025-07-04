import XCTest
import TransloaditKit // ⚠️ WARNING: We are not performing a testable import here. We want to test the real public API. By doing so, we'll know very quicklly if the public API is broken. Which is very important to prevent.
import AVFoundation

class TransloaditKitTests: XCTestCase {
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
    
    fileprivate func makeClient() -> Transloadit {
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

    func testConcurrentAssemblyCreation() throws {
        let expect = expectation(description: "Wait for all assemblies to be created")
        expect.expectedFulfillmentCount = 3
        
        DispatchQueue.concurrentPerform(iterations: 3) { _ in
            do {
                let (files, serverAssembly) = try Network.prepareForUploadingFiles(data: data)
                let numFiles = files.count
                let _ = createAssembly(files) { _ in
                    expect.fulfill()
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        
        wait(for: [expect], timeout: 10)
        
        try transloadit.reset()
    }
    
    func testCanReset() throws {
        XCTAssertEqual(0, transloadit.remainingUploads)
        // Preparation
        let (files, _) = try Network.prepareForUploadingFiles(data: data)
        
        // Start
        createAssembly(files)
        XCTAssertEqual(files.count, transloadit.remainingUploads)
        try? transloadit.reset()
        try? transloadit.reset()
        XCTAssertEqual(0, transloadit.remainingUploads)
    }
    
    func testStatusFetching() throws {
        let (_, serverAssembly) = try Network.prepareForUploadingFiles(data: data)
        Network.prepareNetworkForStatusCheck(assemblyURL: serverAssembly.url, expectedStatus: .uploading)
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
        
        wait(for: [startedUploadsExpectation], timeout: 10)
        
        transloadit.stopRunningUploads()
        // Restart uploads, continue where left off
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fileDelegate.startUploadExpectation = nil
            fileDelegate.finishUploadExpectation = finishedUploadExpectation
            transloadit.start()
        }
        
        wait(for: [finishedUploadExpectation], timeout: 10)
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            secondTransloadit.start()    
        }
        
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
        
        Network.prepareNetworkForStatusCheck(assemblyURL: serverAssembly.url, expectedStatus: statusToTestAgainst)
        
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
    
}
