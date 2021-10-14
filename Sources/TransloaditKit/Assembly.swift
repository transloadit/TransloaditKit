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
    
    // Not a UUID type since the server doesn't hyphenate.
    /// id is always a 32 char UUIDv4 string without dashes
    public let id: String

//    public let status: Status
    let error: String?

    /// Used to upload images
    public let tusURL: URL
    
    /// Used to check the status
    public let url: URL
    
    enum CodingKeys: String, CodingKey {
        case id = "assemblyId"
        // Since the names are tus_url and assembly_ssl_url we only snakecase the breakoff point. So, tusUrl turns into tus_url
        case tusURL = "tusUrl"
        case url = "assemblySslUrl"
        case error
    }
}


public struct AssemblyStatus: Decodable {
    
    // TODO: you get status.status, weird naming
    // TODO: Public enum.... new cases can break public API or document that new cases can be added for unknown default.
    public enum Status: String, Decodable {
        case canceled = "ASSEMBLY_CANCELED"
        case completed = "ASSEMBLY_COMPLETED"
        case executing = "ASSEMBLY_EXECUTING"
        case replaying = "ASSEMBLY_REPLAYING"
        case uploading = "ASSEMBLY_UPLOADING"
        case aborted = "REQUEST_ABORTED"
    }
    
    public let assemblyId: String // Not a UUID type since the server doesn't hyphenate.
    public let message: String
    
    let status: Status
    
    enum CodingKeys: String, CodingKey {
        case assemblyId
        case message
        case status = "ok"
    }
}
