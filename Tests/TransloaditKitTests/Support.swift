import Foundation
@testable import TransloaditKit
import XCTest
enum Files {
    
    static func clearDocumentsDirectory() {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        clearDirectory(dir: docDir)
    }
    
    static func clearDirectory(dir: URL) {
        do {
            let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            for name in names
            {
                let path = "\(dir.path)/\(name)"
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    static func storeFile(data: Data) throws -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let targetLocation = docDir.appendingPathComponent("myfile.txt")
        try data.write(to: targetLocation)
        return targetLocation
    }
    
    static func storeFiles(data: Data, _ amount: Int = 2) throws -> [URL] {
        let urls = try (0..<amount).map { _ in
            try storeFile(data: data)
        }
        return urls
    }
    
}

enum Network {
    
    @discardableResult
    static func prepareForUploadingFiles(data: Data) throws -> ([URL], Assembly) {
        let files = try Files.storeFiles(data: data, 2)
        
        let serverAssembly = Fixtures.makeAssembly()
        Network.prepareAssemblyResponse(assembly: serverAssembly)
        Network.prepareForSuccesfulUploads(url: serverAssembly.tusURL, data: data)
        
        return (files, serverAssembly)
    }
    
    static func prepareAssemblyResponse(assembly: Assembly) {
        let url = URL(string: "https://api2.transloadit.com/assemblies")!
        MockURLProtocol.prepareResponse(for: url, method: "POST") { _ in
            MockURLProtocol.Response(status: 200, headers: [:], data: Fixtures.makeAssemblyResponse(assembly: assembly))
        }
    }
    
    static func prepareForStatusResponse(data: Data) {
        let url = URL(string: "www.tus-image-upload-location-returned-for-creation-post.com")!
        MockURLProtocol.prepareResponse(for: url, method: "HEAD") { _ in
            MockURLProtocol.Response(status: 200, headers: ["Upload-Length": String(data.count),
                                                            "Upload-Offset": "0"], data: nil)
        }
    }
    
    static func prepareForFailingAssemblyResponse() {
        let url = URL(string: "https://api2.transloadit.com/assemblies")!
        MockURLProtocol.prepareResponse(for: url, method: "POST") { _ in
            MockURLProtocol.Response(status: 400, headers: [:], data: nil)
        }
    }
    
    static func prepareForSuccesfulUploads(url: URL, data: Data, lowerCasedKeysInResponses: Bool = false) {
        let uploadURL = URL(string: "www.tus-image-upload-location-returned-for-creation-post.com")!
        MockURLProtocol.prepareResponse(for: url, method: "POST") { _ in
            let key: String
            if lowerCasedKeysInResponses {
                key = "location"
            } else {
                key = "Location"
            }
            return MockURLProtocol.Response(status: 200, headers: [key: uploadURL.absoluteString], data: nil)
        }
        
        // Mimick chunk uploading with offsets
        MockURLProtocol.prepareResponse(for: uploadURL, method: "PATCH") { headers in
            sleep(1) // Upload delay
            guard let headers = headers,
                  let strOffset = headers["Upload-Offset"],
                  let offset = Int(strOffset),
                  let strContentLength = headers["Content-Length"],
                  let contentLength = Int(strContentLength) else {
                      let error = "Did not receive expected Upload-Offset and Content-Length in headers"
                      XCTFail(error)
                      fatalError(error)
                  }
            
            let newOffset = offset + contentLength
            
            let key: String
            if lowerCasedKeysInResponses {
                key = "upload-offset"
            } else {
                key = "Upload-Offset"
            }
            return MockURLProtocol.Response(status: 200, headers: [key: String(newOffset)], data: nil)
        }
        
    }
    
    static func prepareForStatusChecks(assemblyURL statusURL: URL, status: @escaping () -> AssemblyStatus) {
        
        MockURLProtocol.prepareResponse(for: statusURL, method: "GET") { _ in
            let assemblyStatus: AssemblyStatus = status()
            let response = Fixtures.makeAssemblyStatusResponse(assemblyStatus: assemblyStatus)
            
            
            return MockURLProtocol.Response(status: 200, headers: [:], data: response)
        }
    }
    
    static func prepareForStatusCheckFailingOnce(assemblyURL: URL, expectedStatus: AssemblyStatus.ProcessingStatus = .completed) {
        var count = 1
        Network.prepareForStatusChecks(assemblyURL: assemblyURL) {
            if count == 0 {
                return Fixtures.makeAssemblyStatus(status: expectedStatus)
            } else {
                count -= 1
                return Fixtures.makeAssemblyStatus(status: .uploading)
            }
        }
        
    }
    
    static func prepareNetworkForStatusCheck(assemblyURL: URL, expectedStatus: AssemblyStatus.ProcessingStatus = .completed) {
        var count = 1
        Network.prepareForStatusChecks(assemblyURL: assemblyURL) {
            if count == 0 {
                return Fixtures.makeAssemblyStatus(status: expectedStatus)
            } else {
                count -= 1
                return Fixtures.makeAssemblyStatus(status: .uploading)
            }
        }
        
    }
    
}
