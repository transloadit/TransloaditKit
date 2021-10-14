//
//  File.swift
//  
//
//  Created by Tjeerd in ‘t Veen on 07/10/2021.
//

import Foundation


// Services overview
// https://transloadit.com/docs/transcoding/#document-convert
// https://transloadit.com/services/

/// A step that's used to create an Assembly.
public struct Step {
    let name: String
    let robot: String
    let options: [String: Any]
    
    public init(name: String, robot: String, options: [String: Any]) {
        self.name = name
        self.robot = robot
        self.options = options
    }
}

/// An Assembly type, retrieved from a server
public struct Assembly: Decodable {
    
//    public enum Status {
//        case canceled
//        case completed
//        case executing
//        case replaying
//        case uploading
//    }
    
//    /// id is always a 32 char UUIDv4 string without dashes
    public let id: String // TODO: UUID? type?
//    public let status: Status

    /// Used to upload images
    let tusURL: URL
    /// Used to check the status
    let assemblySSLURL: URL
    
    enum CodingKeys: String, CodingKey {
        case id = "assemblyId"
        // Since the names are tus_url and assembly_ssl_url we only snakecase the breakoff point. So, tusUrl turns into tus_url
        case tusURL = "tusUrl"
        case assemblySSLURL = "assemblySslUrl"
    }
}

