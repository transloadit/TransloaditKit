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
    case incompleteServerResponse
}

/// The `TransloaditAPI` class makes API calls, such as creating assemblies or checking an assembly's status.
final class TransloaditAPI: NSObject {
    
    private let basePath = URL(string: "https://api2.transloadit.com")!
    
    enum Endpoint: String {
        case assemblies = "/assemblies"
    }
    
    let configuration: URLSessionConfiguration
    private let delegateQueue: OperationQueue?
    private lazy var session: URLSession = {
        return URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
    }()
    
    static private let formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd HH:mm:s+00:00"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }()
    
    private let credentials: Transloadit.Credentials
    let callbacks = TransloaditCallbacks()
    
    init(credentials: Transloadit.Credentials, session: URLSession) {
        self.credentials = credentials
        self.configuration = session.configuration.copy(withIdentifier: "com.transloadit.bg")
        self.delegateQueue = session.delegateQueue
        super.init()
    }
    
    init(credentials: Transloadit.Credentials, sessionConfiguration: URLSessionConfiguration) {
        self.credentials = credentials
        self.configuration = sessionConfiguration
        self.delegateQueue = nil
        super.init()
    }
    
    func createAssembly(
      templateId: String,
      expectedNumberOfFiles: Int,
      customFields: [String: String],
      completion: @escaping (Result<Assembly, TransloaditAPIError>) -> Void
    ) {
        guard let request = try? makeAssemblyRequest(
          templateId: templateId,
          expectedNumberOfFiles: expectedNumberOfFiles,
          customFields: customFields
        ) else {
            // Next runloop to make the API consistent with the network runloop. Otherwise it would return instantly, can give weird effects
            DispatchQueue.main.async {
                completion(.failure(TransloaditAPIError.cantSerialize))
            }
            return
        }
        
        let task = session.uploadTask(with: request.request, fromFile: request.httpBody)
        callbacks.register(URLSessionCompletionHandler(callback: { result in
            switch result {
            case .failure(let error):
                completion(.failure(.couldNotCreateAssembly(error)))
            case .success((let data, _)):
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
        }), for: task)
        task.resume()
    }
    
    func createAssembly(
      steps: [Step],
      expectedNumberOfFiles: Int,
      customFields: [String: String],
      completion: @escaping (Result<Assembly, TransloaditAPIError>) -> Void
    ) {
        guard let request = try? makeAssemblyRequest(
          steps: steps,
          expectedNumberOfFiles: expectedNumberOfFiles,
          customFields: customFields
        ) else {
            // Next runloop to make the API consistent with the network runloop. Otherwise it would return instantly, can give weird effects
            DispatchQueue.main.async {
                completion(.failure(TransloaditAPIError.cantSerialize))
            }
            return
        }
        
        let task = session.uploadTask(with: request.request, fromFile: request.httpBody)
        callbacks.register(URLSessionCompletionHandler(callback: { result in
            switch result {
            case .failure(let error):
                completion(.failure(.couldNotCreateAssembly(error)))
            case .success((let data, _)):
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
        }), for: task)
        task.resume()
    }
    
    private func makeAssemblyRequest(
      templateId: String, 
      expectedNumberOfFiles: Int,
      customFields: [String: String]
    ) throws -> (request: URLRequest, httpBody: URL) {
        
        func makeBody(includeSecret: Bool) throws -> [String: String] {
            // Time to allow uploads after signing.
            let secondsInDay: Double = 86400
            let dateTime: String = type(of: self).formatter.string(from: Date().addingTimeInterval(secondsInDay))
           
            let authObject = ["key": credentials.key, "expires": dateTime]
            
            var params: [String: Any] = ["auth": authObject, "template_id": templateId]
            params["fields"] = customFields
            
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
            return request
        }
        
        let request = try makeRequest()
        let bodyData = try makeBodyData()
        
        return (request, try writeBodyData(bodyData))
    }
    
    private func makeAssemblyRequest(
      steps: [Step],
      expectedNumberOfFiles: Int,
      customFields: [String: String]
    ) throws -> (request: URLRequest, httpBody: URL) {
        
        func makeBody(includeSecret: Bool) throws -> [String: String] {
            // Time to allow uploads after signing.
            let secondsInDay: Double = 86400
            let dateTime: String = type(of: self).formatter.string(from: Date().addingTimeInterval(secondsInDay))
           
            let authObject = ["key": credentials.key, "expires": dateTime]
            
            var params: [String: Any] = ["auth": authObject, "steps": steps.toDictionary]
            params["fields"] = customFields
            
            let paramsData: Data
            if #available(macOS 10.15, iOS 13.0, *) {
                paramsData = try JSONSerialization.data(withJSONObject: params, options: .withoutEscapingSlashes)
            } else {
                paramsData = try JSONSerialization.data(withJSONObject: params, options: [])
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
            return request
        }
        
        let request = try makeRequest()
        let bodyData = try makeBodyData()
        
        return (request, try writeBodyData(bodyData))
    }
    
    private func writeBodyData(_ data: Data) throws -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bodyDirectory = appSupport.appendingPathComponent("uploads")
        let dataFile = bodyDirectory.appendingPathComponent(UUID().uuidString + ".uploadData")
        
        if !FileManager.default.fileExists(atPath: bodyDirectory.path) {
            try FileManager.default.createDirectory(at: bodyDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        try data.write(to: dataFile)
        
        return dataFile
    }
    
    func fetchStatus(assemblyURL: URL, completion: @escaping (Result<AssemblyStatus, TransloaditAPIError>) -> Void) {
        
        func makeRequest() -> URLRequest {
            var request = URLRequest(url: assemblyURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            request.httpMethod = "GET"
            return request
        }
        
        let task = session.dataTask(with: makeRequest())
        callbacks.register(URLSessionCompletionHandler(callback: { result in
            switch result {
            case .failure:
                completion(.failure(.couldNotFetchStatus))
            case .success((let data, _)):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let status = try decoder.decode(AssemblyStatus.self, from: data)
                    completion(.success(status))
                } catch {
                    completion(.failure(.couldNotFetchStatus))
                }
            }
        }), for: task)
        task.resume()
    }
    
    func cancelAssembly(_ assembly: Assembly, completion: @escaping (Result<AssemblyStatus, TransloaditAPIError>) -> Void) {
        func makeRequest() -> URLRequest {
            var request = URLRequest(url: assembly.url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            request.httpMethod = "DELETE"
            return request
        }
        
        let task = session.dataTask(with: makeRequest())
        callbacks.register(URLSessionCompletionHandler(callback: { result in
            switch result {
            case .failure:
                completion(.failure(.couldNotFetchStatus))
            case .success((let data, _)):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let status = try decoder.decode(AssemblyStatus.self, from: data)
                    completion(.success(status))
                } catch {
                    completion(.failure(.couldNotFetchStatus))
                }
            }
        }), for: task)
        task.resume()
    }
}

class TransloaditCallbacks {
    private var callbacks = [URLSessionTask: URLSessionCompletionHandler]()
    private let syncQueue = DispatchQueue(label: "com.transloadit.callbacks")

    func register(_ callback: URLSessionCompletionHandler, for task: URLSessionTask) {
        syncQueue.sync {
            callbacks[task] = callback
        }
    }

    func remove(for task: URLSessionTask) {
        syncQueue.sync {
            callbacks[task] = nil
        }
    }

    func get(for task: URLSessionTask) -> URLSessionCompletionHandler? {
        return syncQueue.sync {
            return callbacks[task]
        }
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
