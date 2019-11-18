//
//  TransloaditDelegate.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import Foundation

protocol TransloaditDelegate {
    
    // MARK: Upload Progress
    func tranloaditUploadProgress()
    func transloaditUploadFailureBlock()
    
    // MARK: Create
    func transloaditAssemblyCreationResult()
    func transloaditAssemblyCreationError()
    func transloaditTemplateCreationResult()
    func transloaditTemplateCreationError()
    
    // MARK: GET
    func transloaditAssemblyGetResult()
    func transloaditAssemblyGetError()
    func transloaditTemplateGetResult()
    func transloaditTemplateGetError()
    
    // MARK: DELETE
    func transloaditAssemblyDeletionResult()
    func transloaditAssemblyDeletionError()
    func transloaditTemplateDeletionResult()
    func transloaditTemplateDeletionError()
    
    // MARK: Processing
    func transloaditAssemblyProcessResult()
    func transloaditAssemblyProcessError()
    func transloaditAssemblyProcessProgress()
    
}
