//
//  TransloaditDelegate.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import Foundation

public protocol TransloaditDelegate {
    
    // MARK: Upload Progress
    func tranloaditUploadProgress(bytesUploaded uploaded: Int, bytesRemaining remaining: Int)
    func transloaditUploadFailure()
    
    // MARK: Create
    func transloaditCreation(forObject: APIObject, withResult: TransloaditResponse)
    
    // MARK: GET
    func transloaditGet(forObject: APIObject, withResult: TransloaditResponse)
    
    
    // MARK: DELETE
    func transloaditDeletion(forObject: APIObject, withResult: TransloaditResponse)

    
    // MARK: Processing
    func transloaditProcessing(forObject: APIObject, withResult: TransloaditResponse)
    func transloaditProcessingFailure(forObject: APIObject, withResult: TransloaditResponse)

    
}
