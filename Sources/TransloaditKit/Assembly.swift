//
//  Assembly.swift
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
public struct Assembly: Codable, Equatable {
    
    // Not a UUID type since the server doesn't hyphenate.
    /// id is always a 32 char UUIDv4 string without dashes
    public let id: String

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

extension Assembly: CustomStringConvertible {
    public var description: String {
        "\(id),\(error ?? ""),\(tusURL.absoluteString),\(url.absoluteString)"
    }
    
    init?(fromString: String) {
        let values = fromString.components(separatedBy: ",")
        guard values.count == 4 else { return nil }
        
        self.id = values[0]
        
        self.error = values[1].isEmpty ? nil : values[1]
        guard let tusURL = URL(string: values[2]) else { return nil }
        guard let url = URL(string: values[3]) else { return nil }
        
        self.tusURL = tusURL
        self.url = url
    }
    
    
}

public struct AssemblyStatus: Codable {
    
    /// The stauts of an Assembly. Use an @unknown default switch on this, for if cases are added.
    public enum ProcessingStatus: String, Decodable {
        case canceled = "ASSEMBLY_CANCELED"
        case completed = "ASSEMBLY_COMPLETED"
        case executing = "ASSEMBLY_EXECUTING"
        case replaying = "ASSEMBLY_REPLAYING"
        case uploading = "ASSEMBLY_UPLOADING"
        case aborted = "REQUEST_ABORTED"
    }
    
    public let assemblyID: String // Not a UUID type since the server doesn't hyphenate.
    public let message: String
    public let processingStatus: ProcessingStatus
    
    enum CodingKeys: String, CodingKey {
        case assemblyID = "assemblyId"
        case message
        case processingStatus = "ok"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assemblyID, forKey: .assemblyID)
        try container.encode(message, forKey: .message)
        try container.encode(processingStatus.rawValue, forKey: .processingStatus)
    }
    
}
