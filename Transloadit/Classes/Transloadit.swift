//
//  Transloadit.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import UIKit
import TUSKit

public class Transloadit: NSObject, URLSessionTaskDelegate {

    private static var config: TransloaditConfig?

    internal var transloaditSession: TransloaditSession = TransloaditSession()

    static public var shared: Transloadit = Transloadit()
    private let executor: TransloaditExecutor

    public var delegate: TransloaditDelegate?
    
    public class func setup(with config:TransloaditConfig){
        Transloadit.config = config
    }
    
    private override init() {
        executor = TransloaditExecutor(withKey: Transloadit.config!.publicKey, andSecret: Transloadit.config!.privateKey)

        super.init()
        
        transloaditSession = TransloaditSession(customConfiguration: URLSessionConfiguration.default, andDelegate: self)
    }
    
    internal func invoke(assembly: Assembly) {
        executor.create(assembly)
    }
    
    public func newAssembly() -> Assembly {
        return Assembly()
    }
    
}
