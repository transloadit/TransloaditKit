//
//  TransloaditConifg.swift
//  Transloadit
//
//  Created by Mark Robert Masterson on 10/25/20.
//

import Foundation

public struct TransloaditConfig {
    var uploadURL: URL
    var URLSessionConfig: URLSessionConfiguration = URLSessionConfiguration.default
    public var logLevel: TransloaditLogLevel = .Off
    
    public init(withUploadURLString uploadURLString: String, andSessionConfig sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.uploadURL = URL(string: uploadURLString)!
        self.URLSessionConfig = sessionConfig
    }
    
    public init(withUploadURL uploadURL: URL, andSessionConfig sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.uploadURL = uploadURL
        self.URLSessionConfig = sessionConfig
    }
}
