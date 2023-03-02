//
//  TransloaditAPI.swift
//  
//
//  Created by Tjeerd in ‘t Veen on 13/10/2021.
//

import Foundation
import CommonCrypto
import TUSKit

enum TransloaditAPIError: Error {
    case cantSerialize
    case couldNotFetchStatus
    case couldNotCreateAssembly(Error)
    case assemblyError(String)
}

/// The `TransloaditAPI` class makes API calls, such as creating assemblies or checking an assembly's status.
final class TransloaditAPI {
    
    private let basePath = URL(string: "https://api2.transloadit.com")!
    
    enum Endpoint: String {
        case assemblies = "/assemblies"
    }
    
    private let session: URLSession
    
    static private let formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd HH:mm:s+00:00"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }()
    
    private let credentials: Transloadit.Credentials
    
    init(credentials: Transloadit.Credentials, session: URLSession) {
        self.credentials = credentials
        self.session = session
    }
    
    func createAssembly(templateId: String, expectedNumberOfFiles: Int, completion: @escaping (Result<Assembly, TransloaditAPIError>) -> Void) {
        guard let request = try? makeAssemblyRequest(templateId: templateId, expectedNumberOfFiles: expectedNumberOfFiles) else {
            // Next runloop to make the API consistent with the network runloop. Otherwise it would return instantly, can give weird effects
            DispatchQueue.main.async {
                completion(.failure(TransloaditAPIError.cantSerialize))
            }
            return
        }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let assembly = try decoder.decode(Assembly.self, from: data)
                    
                    if let error = assembly.error {
                        completion(.failure(.assemblyError(error)))
                    } else {
                        completion(.success(assembly))
                    }
                } catch {
                    completion(.failure(TransloaditAPIError.couldNotCreateAssembly(error)))
                }
            }
        }
        task.resume()
    }
    
    func createAssembly(steps: [Step], expectedNumberOfFiles: Int, completion: @escaping (Result<Assembly, TransloaditAPIError>) -> Void) {
        guard let request = try? makeAssemblyRequest(steps: steps, expectedNumberOfFiles: expectedNumberOfFiles) else {
            // Next runloop to make the API consistent with the network runloop. Otherwise it would return instantly, can give weird effects
            DispatchQueue.main.async {
                completion(.failure(TransloaditAPIError.cantSerialize))
            }
            return
        }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let assembly = try decoder.decode(Assembly.self, from: data)
                    
                    if let error = assembly.error {
                        completion(.failure(.assemblyError(error)))
                    } else {
                        completion(.success(assembly))
                    }
                } catch {
                    completion(.failure(TransloaditAPIError.couldNotCreateAssembly(error)))
                }
            }
        }
        task.resume()
    }
    
    private func makeAssemblyRequest(templateId: String, expectedNumberOfFiles: Int) throws -> URLRequest {
        
        func makeBody(includeSecret: Bool) throws -> [String: String] {
            // Time to allow uploads after signing.
            let secondsInDay: Double = 86400
            let dateTime: String = type(of: self).formatter.string(from: Date().addingTimeInterval(secondsInDay))
           
            let authObject = ["key": credentials.key, "expires": dateTime]
            
            let params: [String: Any] = ["auth": authObject, "template_id": templateId]
            
            let paramsData: Data
            if #available(macOS 10.15, iOS 13.0, *) {
                paramsData = try JSONSerialization.data(withJSONObject: params, options: .withoutEscapingSlashes)
            } else {
                paramsData = try! JSONSerialization.data(withJSONObject: params, options: [])
            }
            
            guard let paramsJSONString = String(data: paramsData, encoding: .utf8) else {
                throw TransloaditAPIError.cantSerialize
            }
            
            var body: [String: String] = ["params": paramsJSONString, "tus_num_expected_upload_files": String(expectedNumberOfFiles)]
            if !credentials.secret.isEmpty {
                body["signature"] = "sha384:" + paramsJSONString.hmac(key: credentials.secret)
            }
            
            return body
        }
        
        let boundary = UUID.init().uuidString
        
        func makeBodyData() throws -> Data {
            let formFields = try makeBody(includeSecret: true)
            var body: Data = Data()
            for field in formFields {
                [String(format: "--%@\r\n", boundary),
                 String(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", field.key),
                 String(format: "%@\r\n", field.value)]
                    .forEach { string in
                        body.append(Data(string.utf8))
                    }
            }
            let string = String(format: "--%@--\r\n", boundary)
            body.append(Data(string.utf8))
            return body
        }
        
        func makeRequest() throws -> URLRequest {
            let path = basePath.appendingPathComponent(Endpoint.assemblies.rawValue)
            var request: URLRequest = URLRequest(url: path, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
            
            let headers = ["Content-Type": String(format: "multipart/form-data; boundary=%@", boundary)]
            
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = try makeBodyData()
            return request
        }
        
        let request = try makeRequest()
        

        return request
    }
    
    private func makeAssemblyRequest(steps: [Step], expectedNumberOfFiles: Int) throws -> URLRequest {
        
        func makeBody(includeSecret: Bool) throws -> [String: String] {
            // Time to allow uploads after signing.
            let secondsInDay: Double = 86400
            let dateTime: String = type(of: self).formatter.string(from: Date().addingTimeInterval(secondsInDay))
           
            let authObject = ["key": credentials.key, "expires": dateTime]
            
            let params = ["auth": authObject, "steps": steps.toDictionary]
            
            let paramsData: Data
            if #available(macOS 10.15, iOS 13.0, *) {
                paramsData = try JSONSerialization.data(withJSONObject: params, options: .withoutEscapingSlashes)
            } else {
                paramsData = try! JSONSerialization.data(withJSONObject: params, options: [])
            }
            
            guard let paramsJSONString = String(data: paramsData, encoding: .utf8) else {
                throw TransloaditAPIError.cantSerialize
            }
            
            var body: [String: String] = ["params": paramsJSONString, "tus_num_expected_upload_files": String(expectedNumberOfFiles)]
            if !credentials.secret.isEmpty {
                body["signature"] = "sha384:" + paramsJSONString.hmac(key: credentials.secret)
            }
            
            return body
        }
        
        let boundary = UUID.init().uuidString
        
        func makeBodyData() throws -> Data {
            let formFields = try makeBody(includeSecret: true)
            var body: Data = Data()
            for field in formFields {
                [String(format: "--%@\r\n", boundary),
                 String(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", field.key),
                 String(format: "%@\r\n", field.value)]
                    .forEach { string in
                        body.append(Data(string.utf8))
                    }
            }
            let string = String(format: "--%@--\r\n", boundary)
            body.append(Data(string.utf8))
            return body
        }
        
        func makeRequest() throws -> URLRequest {
            let path = basePath.appendingPathComponent(Endpoint.assemblies.rawValue)
            var request: URLRequest = URLRequest(url: path, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
            
            let headers = ["Content-Type": String(format: "multipart/form-data; boundary=%@", boundary)]
            
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = try makeBodyData()
            return request
        }
        
        let request = try makeRequest()
        

        return request
    }
    
    func fetchStatus(assemblyURL: URL, completion: @escaping (Result<AssemblyStatus, TransloaditAPIError>) -> Void) {
        
        func makeRequest() -> URLRequest {
            var request = URLRequest(url: assemblyURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            request.httpMethod = "GET"
            return request
        }
        
        let task = session.dataTask(request: makeRequest()) { result in
            switch result {
            case .success((let data?, _)):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let status = try decoder.decode(AssemblyStatus.self, from: data)
                    completion(.success(status))
                } catch {
                    completion(.failure(.couldNotFetchStatus))
                }
            case .success((nil, _)):
                completion(.failure(.couldNotFetchStatus))
            case .failure:
                completion(.failure(.couldNotFetchStatus))
            }
        }
        
        task.resume()
    }
}


extension String {

    func hmac(key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA384), key, key.count, self, self.count, &digest)
        let data = Data(digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
    }

}

extension Array where Element == Step {
    /// Generate API friendly dictionary to create an Assembly, based on steps.
    var toDictionary: [String: Any] {
        var values = [String: Any]()
        
        for step in self {
            var combinedOptions = step.options
            combinedOptions["robot"] = step.robot
            values[step.name] = combinedOptions
        }
        
        return values
    }
}

// From Alamofire
extension CharacterSet {
    /// Creates a CharacterSet from RFC 3986 allowed characters.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    public static let realURLQueryAllowed: CharacterSet = {
        let generalDelimitersToEncode = "#[]@/?+:" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*;="
        let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        
        return CharacterSet.urlHostAllowed.subtracting(encodableDelimiters)
    }()
}
