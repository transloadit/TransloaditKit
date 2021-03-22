//
//  Assembly.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import UIKit
import TUSKit

public class Assembly: APIObject {

    var numberOfFiles: Int?
    
    internal var tusUpload: TUSUpload?
    public var assemblyURL: String?

    
    internal var steps: NSMutableDictionary = [:]
    internal var custom: NSMutableDictionary = [:]

    
    public override init() {
        //
    }
    
    
    
    public func addFile(withPathURL: URL) {
        tusUpload = TUSUpload(withId: withPathURL.lastPathComponent, andFilePathURL: withPathURL, andFileType: withPathURL.pathExtension)
    }

    
    public func addStep(name: String, options: [String: Any]) {
        steps[name] = options
    }
    
    public func addCustomParam(key: String, dictionary: [String: Any]) {
        custom[key] = dictionary
    }
    
    public func addCustomParam(key: String, string: String) {
        custom[key] = string
    }
    
    @available(*, deprecated, renamed: "create")
    public func save() {
        Transloadit.shared.invoke(assembly: self)
    }
    
    public func create() {
        Transloadit.shared.invoke(assembly: self)
    }
    
}
