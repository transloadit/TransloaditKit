//
//  File.swift
//  
//
//  Created by Tjeerd in ‘t Veen on 19/10/2021.
//

@testable import TransloaditKit
import Foundation

enum Fixtures {
    
    // We make Assembly and AssemblyStatus here because we can access their initializers (via testable import). Which we can't in TransloaditKitTests (on purpose to test public API). We have no need to expose the memberwise initializers from these types to the public API either.
    
    static func makeAssembly() -> Assembly {
        Assembly(id: "abc", error: nil, tusURL: URL(string: "https://my-tus.transloadit.com")!, url: URL(string: "https://transloadit.com")!)
    }
    
    static func makeAssemblyStatus(status: AssemblyStatus.Status) -> AssemblyStatus {
        AssemblyStatus(assemblyId: "Assembly ID", message: "I am a message", status: status)
    }
    
    static func makeAssemblyResponse(assembly: Assembly) -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(assembly)
        return data
        // If we want to get the JSON dict
//        let dict = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.fragmentsAllowed)
//        return dict
    }
    
    static func makeAssemblyStatusResponse(assemblyStatus: AssemblyStatus) -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(assemblyStatus)
        return data
    }
}
