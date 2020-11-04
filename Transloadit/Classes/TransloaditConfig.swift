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
    public init(withKey: String, andSecret: String) {
        publicKey = withKey
        privateKey = andSecret
    }
    
}
