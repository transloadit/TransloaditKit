//
//  File.swift
//  
//
//  Created by Tjeerd in ‘t Veen on 07/10/2021.
//

import Foundation

/// An Assembly type, retrieved from a server
public struct Assembly {
    
    public enum Status {
        case canceled
        case completed
        case executing
        case replaying
        case uploading
    }
    
    /// id is always a 32 char UUIDv4 string without dashes
    public let id: UUID // TODO: UUID? type?
    public let status: Status
    public let statusCode: Int
    let error: String? // TODO: Maybe enum?
    
    /// Used to upload images
    let tusURL: String
    /// Used to check the status
    let assemblySSLURL: String
    
    /// Upload status bytes received
    let bytesReceived: Int
    /// Upload status bytes expected
    let bytesExpected: Int
}

