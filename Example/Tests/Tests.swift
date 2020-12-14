//
//  UploadTest.swift
//  TUSKit_Tests
//
//  Created by Mark Robert Masterson on 10/10/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
import Transloadit

class UploadTest: XCTestCase, TransloaditDelegate {
    
    func tranloaditUploadProgress(bytesUploaded uploaded: Int, bytesRemaining remaining: Int) {
        //
    }
    
    func transloaditUploadFailure() {
        //
    }
    
    func transloaditCreation(forObject: APIObject, withResult: TransloaditResponse) {
        //
        passedUpload = withResult.success
        uploadExpectation.fulfill()
        
    }
    
    func transloaditGet(forObject: APIObject, withResult: TransloaditResponse) {
        //
    }
    
    func transloaditDeletion(forObject: APIObject, withResult: TransloaditResponse) {
        //
    }
    
    func transloaditProcessing(forObject: APIObject, withResult: TransloaditResponse) {
        //
        passedProcessing = withResult.success
        prcoessingExpectation.fulfill()

    }
    
    func transloaditProcessingFailure(forObject: APIObject, withResult: TransloaditResponse) {
        //
    }
    
    var passedUpload = false
    var passedProcessing = false

    private var uploadExpectation: XCTestExpectation!
    private var prcoessingExpectation: XCTestExpectation!

    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        uploadExpectation = expectation(description: "Success")
        prcoessingExpectation = expectation(description: "Success")

        let config = TransloaditConfig()
        Transloadit.setup(with: config)
        Transloadit.shared.delegate = self
        let testBundle = Bundle.main
        guard let fileURL = testBundle.url(forResource: "memeCat", withExtension: "jpg")
        else { fatalError() }
        
        
        var newSteps: [String: Any] = [:]
        newSteps["robot"] = "/image/resize"
        newSteps["width"] = 75
        
        let assembly: Assembly = Transloadit.shared.newAssembly()
        
        assembly.addStep(name: "resize", options: newSteps)
        assembly.addCustomParam(key: "Custom", dictionary: ["TestKey": "TestValue"])
        assembly.addCustomParam(key: "Custom2", string: "TestValue2")

        assembly.addFile(withPathURL: fileURL )
        assembly.create()
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testUpload() throws {
        waitForExpectations(timeout: 100)
        XCTAssertTrue(passedUpload)
    }
    
    func testProcessing() throws {
        waitForExpectations(timeout: 100)
        XCTAssertTrue(passedProcessing)
    }


}
