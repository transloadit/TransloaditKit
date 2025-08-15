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
    case apiIsNil
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
    private let signatureGenerator: SignatureGenerator
    
    let callbacks = TransloaditCallbacks()
    
    init(credentials: Transloadit.Credentials, session: URLSession, signatureGenerator: @escaping SignatureGenerator) {
        self.credentials = credentials
        self.configuration = session.configuration.copy(withIdentifier: "com.transloadit.bg")
        self.delegateQueue = session.delegateQueue
        self.signatureGenerator = signatureGenerator
        super.init()
    }
    
    init(credentials: Transloadit.Credentials, sessionConfiguration: URLSessionConfiguration, signatureGenerator: @escaping SignatureGenerator) {
        self.credentials = credentials
        self.configuration = sessionConfiguration
        self.delegateQueue = nil
        self.signatureGenerator = signatureGenerator
        super.init()
    }
    
    func createAssembly(
      templateId: String,
      expectedNumberOfFiles: Int,
      customFields: [String: String],
      completion: @escaping (Result<Assembly, TransloaditAPIError>) -> Void
    ) {
        let params: [String: Any] = [
            "template_id": templateId,
            "fields": customFields
        ]
        
        createAssembly(
            params: params,
            expectedNumberOfFiles: expectedNumberOfFiles,
            customFields: customFields,
            completion: completion
        )
    }
    
    func createAssembly(
      steps: [Step],
      expectedNumberOfFiles: Int,
      customFields: [String: String],
      completion: @escaping (Result<Assembly, TransloaditAPIError>) -> Void
    ) {
        let params = [
            "steps": steps.toDictionary
        ]
        
        createAssembly(
            params: params,
            expectedNumberOfFiles: expectedNumberOfFiles,
            customFields: customFields,
            completion: completion
        )
    }
    
    private func createAssembly(
        params: [String: Any],
        expectedNumberOfFiles: Int,
        customFields: [String: String],
        completion: @escaping (Result<Assembly, TransloaditAPIError>) -> Void
    ) {
        makeAssemblyRequest(
            params: params,
            expectedNumberOfFiles: expectedNumberOfFiles,
            customFields: customFields
        ) { result in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                    completion(.failure(TransloaditAPIError.cantSerialize))
                }
            case .success((let request, let httpBody)):
                let task = self.session.uploadTask(with: request, fromFile: httpBody)
                self.callbacks.register(URLSessionCompletionHandler(callback: { result in
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
                            completion(.failure(.couldNotCreateAssembly(error)))
                        }
                    }
                }), for: task)
                task.resume()
            }
        }

    }
    
    private func makeAssemblyRequest(
        params: [String: Any],
        expectedNumberOfFiles: Int,
        customFields: [String: String],
        assemblyRequestCreated: @escaping (Result<(request: URLRequest, httpBody: URL), Error>) -> Void
    ) {
        let boundary = UUID.init().uuidString
        
        do {
            let request = try assemblyURLRequest(boundary: boundary)
            
            makeBodyDataForAssemblyRequest(
                using: params,
                expectedNumberOfFiles: expectedNumberOfFiles,
                boundary: boundary
            ) { [weak self] result in
                guard let self else {
                    assemblyRequestCreated(.failure(TransloaditError.couldNotCreateAssembly(underlyingError: TransloaditAPIError.apiIsNil)))
                    return
                }
                do {
                    let bodyData = try result.get()
                    let bodyURL = try self.writeBodyData(bodyData)
                    assemblyRequestCreated(.success((request, bodyURL)))
                } catch {
                    assemblyRequestCreated(.failure(TransloaditError.couldNotCreateAssembly(underlyingError: error)))
                }
            }
        } catch {
            assemblyRequestCreated(.failure(TransloaditError.couldNotCreateAssembly(underlyingError: error)))
        }
    }
    
    private func assemblyURLRequest(boundary: String) throws -> URLRequest {
        let path = basePath.appendingPathComponent(Endpoint.assemblies.rawValue)
        var request: URLRequest = URLRequest(url: path, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        
        let headers = ["Content-Type": String(format: "multipart/form-data; boundary=%@", boundary)]
        
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        return request
    }
    
    private func makeBodyDataForAssemblyRequest(
        using params: [String: Any],
        expectedNumberOfFiles: Int,
        boundary: String,
        bodyDataCreated: @escaping (Result<Data, Error>) -> Void
    ) {
        makeBodyForAssemblyRequest(
            using: params,
            expectedNumberOfFiles: expectedNumberOfFiles
        ) { result in
            do {
                let formFields = try result.get()
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
                
                bodyDataCreated(.success(body))
            } catch {
                bodyDataCreated(.failure(TransloaditError.couldNotCreateAssembly(underlyingError: error)))
            }
        }
    }
    
    private func makeBodyForAssemblyRequest(
        using params: [String: Any],
        expectedNumberOfFiles: Int,
        bodyCreated: @escaping (Result<[String: String], Error>) -> Void
    ) {
        var params = params
        
        // Time to allow uploads after signing.
        let secondsInDay: Double = 86400
        let dateTime: String = type(of: self).formatter.string(from: Date().addingTimeInterval(secondsInDay))
       
        let authObject = ["key": credentials.key, "expires": dateTime]
        params["auth"] = authObject
        
        do {
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
            signatureGenerator(paramsJSONString) { signatureResult in
                do {
                    let signature = try signatureResult.get()
                    body["signature"] = signature
                    bodyCreated(.success(body))
                } catch {
                    bodyCreated(.failure(TransloaditError.couldNotCreateAssembly(underlyingError: error)))
                }
            }
        } catch {
            bodyCreated(.failure(TransloaditError.couldNotCreateAssembly(underlyingError: error)))
            
        }
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
