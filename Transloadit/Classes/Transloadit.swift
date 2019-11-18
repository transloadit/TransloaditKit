//
//  Transloadit.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import UIKit
import TUSKit

class Transloadit: NSObject {

    var delegate: TransloaditDelegate?
    var tusSession: TUSSession?
    
    public override init() {
        super.init()
        tusSession = TUSSession()
    }
    
    // MARK: CRUD
    
    public func create(_ object: APIObject) {
        
        self.makeRequest(withMethod: .POST, andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
                    self.delegate?.transloaditAssemblyCreationResult()
                }
                if object.isKind(of: Template.self) {
                    self.delegate?.transloaditTemplateCreationResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
                    self.delegate?.transloaditAssemblyCreationError()
                }
                if object.isKind(of: Template.self) {
                    self.delegate?.transloaditTemplateCreationError()
                }
            }
        })
    }
    
    public func get(_ object: APIObject) {
        self.makeRequest(withMethod: .GET, andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
                    self.delegate?.transloaditAssemblyGetResult()
                }
                if object.isKind(of: Template.self) {
                    self.delegate?.transloaditTemplateGetResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
                    self.delegate?.transloaditAssemblyGetError()
                }
                if object.isKind(of: Template.self) {
                    self.delegate?.transloaditTemplateGetError()
                }
            }
        })
    }
    
    public func update(_ object: APIObject) {
        self.makeRequest(withMethod: .PUT, andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
                    self.delegate?.transloaditAssemblyGetResult()
                }
                if object.isKind(of: Template.self) {
                    self.delegate?.transloaditTemplateGetResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
                    self.delegate?.transloaditAssemblyGetError()
                }
                if object.isKind(of: Template.self) {
                    self.delegate?.transloaditTemplateGetError()
                }
            }
        })
    }
    
    public func delete(_ object: APIObject) {
        self.makeRequest(withMethod: .DELETE, andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
                    self.delegate?.transloaditAssemblyDeletionResult()
                }
                if object.isKind(of: Template.self) {
                    self.delegate?.transloaditTemplateDeletionResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
                    self.delegate?.transloaditAssemblyDeletionError()
                }
                if object.isKind(of: Template.self) {
                    self.delegate?.transloaditTemplateDeletionError()
                }
            }
        })
    }
    
    // MARK: Assembly
    
    public func invokeAssembly() {
        
    }
    
    //MARK: PRIVATE
    
    // MARK: Networking
    
    private func makeRequest(withMethod method: MethodType, andObject object: APIObject, callback: @escaping (_ reponse: TransloaditResponse) -> Void ){
        
        var endpoint: String = ""
        var request: TransloaditRequest?
        if (object.isKind(of: Assembly.self)) {
            endpoint = TRANSLOADIT_API_ASSEMBLIES
        } else if (object.isKind(of: Template.self)) {
            endpoint = TRANSLOADIT_API_TEMPLATE
        }
        
        request = TransloaditRequest()
        var url: String = String(format: "%@%@", TRANSLOADIT_BASE_PROTOCOL, TRANSLOADIT_BASE_URL, endpoint)
        
        let dataTask = tusSession!.session().dataTask(with: request! as URLRequest) { (data, response, error) in
            callback(TransloaditResponse())
        }
        
        dataTask.resume()
    }
    
    
}
