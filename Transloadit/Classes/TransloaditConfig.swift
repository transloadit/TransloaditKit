//
//  TransloaditConfig.swift
//  TUSKit
//
//  Created by Mark Robert Masterson on 10/25/20.
//

import Foundation

public struct TransloaditConfig {
    internal var publicKey: String = ""
    internal var privateKey: String = ""
    
    public init() {
        guard let path = Bundle.main.path(forResource: "Transloadit", ofType: "plist") else {
            fatalError("Error - Transloadit.plist not found.")
        }
        let plist = NSDictionary(contentsOfFile: path)
        publicKey = plist?.value(forKey: "key") as! String
        if (plist?.value(forKey: "secret") != nil) {
            privateKey = plist?.value(forKey: "secret") as! String
        }
    }
    
    public init(withKey: String) {
        publicKey = withKey
    }
    
    public init(withKey: String, andSecret: String) {
        publicKey = withKey
        privateKey = andSecret
    }
    
    internal func useSecretKeyAuth() -> Bool {
        return privateKey.isEmpty ? false : true
    }
    
}
