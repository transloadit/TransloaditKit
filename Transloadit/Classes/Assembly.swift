//
//  Assembly.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import UIKit

public class Assembly: APIObject {

    var numberOfFiles: Int?
    
    internal var steps: [String: Any] = [:]
    
    public override init() {
        //
    }
    
    
    public func addFile(withData: Data) {
        
    }
    
    public func addFile(withPathURL: URL) {
        
    }

    
    public func addStep(name: String, options: [String: Any]) {
        steps[name] = options
    }
    
    public func save() {

        Transloadit.shared.invoke(assembly: self)
    }
    
}
