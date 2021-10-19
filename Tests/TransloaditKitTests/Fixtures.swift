//
//  File.swift
//  
//
//  Created by Tjeerd in ‘t Veen on 19/10/2021.
//

@testable import TransloaditKit
import Foundation

enum Fixtures {
    static func makeAssembly() -> Assembly {
        Assembly(id: "abc", error: nil, tusURL: URL(string: "https://my-tus.transloadit.com")!, url: URL(string: "https://transloadit.com")!)
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
}
