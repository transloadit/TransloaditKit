//
//  TransloaditDelegate.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import Foundation

public protocol TransloaditDelegate {
    
    // MARK: Upload Progress
    func tranloaditUploadProgress()
    func transloaditUploadFailureBlock()
    
    // MARK: Create
    func transloaditCreationResult(forObject: APIObject, withResult: TransloaditResponse)
    
    // MARK: GET
    func transloaditGetResult(forObject: APIObject, withResult: TransloaditResponse)
    
    
    // MARK: DELETE
    func transloaditDeletionResult(forObject: APIObject, withResult: TransloaditResponse)

    
    // MARK: Processing
    func transloaditProcessResult()
    func transloaditProcessProgress()
    
}
