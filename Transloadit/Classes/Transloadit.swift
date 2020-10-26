//
//  Transloadit.swift
//  Pods
//
//  Created by Mark Robert Masterson on 11/17/19.
//

import UIKit
import TUSKit

public class Transloadit: NSObject, URLSessionTaskDelegate {

    var tusClient: TUSClient?
    private static var config: TransloaditConfig?
    private let executor: TransloaditExecutor

    internal var transloaditSession: TransloaditSession = TransloaditSession()

    static public var shared: Transloadit = Transloadit()
    
    public var delegate: TransloaditDelegate?
    
    public class func setup(with config:TransloaditConfig){
        Transloadit.config = config
    }
    
    private override init() {
        guard let config = Transloadit.config else {
            fatalError("Error - you must call setup before accessing Transloadit")
        }
        var tusConfig = TUSConfig(withUploadURLString: "https://tusd.tusdemo.net/files")
//        config.logLevel = .All
        TUSClient.setup(with: tusConfig)
        executor = TransloaditExecutor(withKey: "", andSecret: "")
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
