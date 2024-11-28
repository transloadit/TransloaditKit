//
//  TransloadItMockDelegate.swift
//  
//
//  Created by Tjeerd in ‘t Veen on 18/11/2021.
//

import XCTest
import TransloaditKit
import Foundation

final class TransloadItMockDelegate: TransloaditFileDelegate {
    struct Progress {
        let bytesUploaded: Int
        let totalBytes: Int
    }
    
    var name: String? = nil
    
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
