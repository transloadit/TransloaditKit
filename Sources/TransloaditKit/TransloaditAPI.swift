//
//  File.swift
//  
//
//  Created by Tjeerd in ‘t Veen on 13/10/2021.
//

import Foundation
import CommonCrypto

enum TransloaditAPIError: Error {
    case cantSerialize
    case couldNotFetchStatus
    case couldNotCreateAssembly(Error)
    case assemblyError(String)
}

final class TransloaditAPI {
    
    private let basePath = URL(string: "https://api2.transloadit.com")!
    
    enum Endpoint: String {
        case assemblies = "/assemblies"
    }
    
    private let session: URLSession
    
    static private let formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd HH:mm:s+00:00"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }()
    
    private let credentials: Transloadit.Credentials
    
    init(credentials: Transloadit.Credentials, session: URLSession) {
        self.credentials = credentials
        self.session = session
    }
    func createAssembly(steps: [Step], expectedNumberOfFiles: Int, completion: @escaping (Result<Assembly, TransloaditAPIError>) -> Void) {
        guard let request = try? makeRequest(steps: steps, expectedNumberOfFiles: expectedNumberOfFiles) else {
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
    
    private func makeRequest(steps: [Step], expectedNumberOfFiles: Int) throws -> URLRequest {
        
        func makeBody(includeSecret: Bool) throws -> [String: String] {
            // TODO: Why + 300? Remainder from previous codebase.
            let dateTime: String = type(of: self).formatter.string(from: Date().addingTimeInterval(300))
           
            let authObject = ["key": credentials.key, "expires": dateTime]
            
            // TODO: Merge custom values?
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
            
            // TODO: Support multiple upload files
            var body: [String: String] = ["params": paramsJSONString, "tus_num_expected_upload_files": String(expectedNumberOfFiles)]
            if !credentials.secret.isEmpty {
                body["signature"] = paramsJSONString.hmac(key: credentials.secret)
            }
            
            return body
        }
        
        let boundary = UUID.init().uuidString
        
        func makeBodyData() throws -> Data {
            let formFields = try makeBody(includeSecret: true)
            var body: Data = Data()
            for field in formFields {
                // TODO: Force unwrap
                body.append(String(format: "--%@\r\n", boundary).data(using: .utf8)!)
                body.append(String(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", field.key).data(using: .utf8)!)
                body.append(String(format: "%@\r\n", field.value).data(using: .utf8)!)
            }
            body.append(String(format: "--%@--\r\n", boundary).data(using: .utf8)!)
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
                // TODO: Underlying error?
                completion(.failure(.couldNotFetchStatus))
            }
        }
        
        task.resume()
    }
    
    /*
    public func assemblyStatus(forAssembly: Assembly) {
        print(forAssembly.assemblyURL!)
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            var request: URLRequest = URLRequest(url: URL(string: forAssembly.assemblyURL!)!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
            request.httpMethod = "GET"
            Transloadit.shared.transloaditSession.session.dataTask(with: request as URLRequest) { (data, response, error) in
                var responseData = [String: Any]()
                let transloaditResponse = TransloaditResponse()

                guard let data = data, error == nil else { return }
                do {
                    responseData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                    if (responseData["ok"] as! String == "ASSEMBLY_COMPLETED") {
                        transloaditResponse.processing = false
                        transloaditResponse.success = true
                        timer.invalidate()
                    } else {
                        transloaditResponse.processing = true
                    }
                    Transloadit.shared.delegate?.transloaditProcessing(forObject: forAssembly, withResult: transloaditResponse)
                } catch let error as NSError {
                    print(error)
                }
            }.resume()
        }
    }
     */
    
    /*
    private func urlRequest(withMethod method: String, andObject object: APIObject, callback: @escaping (_ reponse: TransloaditResponse) -> Void ){
        var endpoint: String = ""
        if (object.isKind(of: Assembly.self)) {
            endpoint = TRANSLOADIT_API_ASSEMBLIES
        } else if (object.isKind(of: Template.self)) {
            endpoint = TRANSLOADIT_API_TEMPLATE
        }
        
        let boundary = UUID.init().uuidString
        let headers = ["Content-Type": String(format: "multipart/form-data; boundary=%@", boundary)]
        
        
        let formFields = generateBody(forAPIObject: object, includeSecret: true)
        var body: Data = Data()
        for field in formFields {
            body.append(String(format: "--%@\r\n", boundary).data(using: .utf8)!)
            body.append(String(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", field.key).data(using: .utf8)!)
            body.append(String(format: "%@\r\n", field.value).data(using: .utf8)!)
        }
        body.append(String(format: "--%@--\r\n", boundary).data(using: .utf8)!)
        
        let url: String = String(format: "%@%@%@", TRANSLOADIT_BASE_PROTOCOL, TRANSLOADIT_BASE_URL, endpoint)
        var request: URLRequest = URLRequest(url: URL(string: url)!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        
        request.httpMethod = method
        print(request.debugDescription)
        let dataTask = Transloadit.shared.transloaditSession.session.dataTask(with: request as URLRequest) { (data, response, error) in
            var resonseData = [String: Any]()
            let transloaditResponse = TransloaditResponse()
            guard let data = data, error == nil else { return }
            do {
                resonseData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                if let httpResponse = response as? HTTPURLResponse {
                    if (httpResponse.statusCode >= 400) {
                        //TODO: Fix to JSON Serialization
                        transloaditResponse.success = false
                        transloaditResponse.statusCode = httpResponse.statusCode
                        transloaditResponse.error = resonseData["error"] as! String
                    } else {
                        //TODO: Fix to JSON Serialization
                        transloaditResponse.tusURL = resonseData["tus_url"]! as! String
                        transloaditResponse.assemblyURL = resonseData["assembly_ssl_url"]! as! String
                    }
                    callback(transloaditResponse)
                }
            } catch let error as NSError {
                print(error)
                transloaditResponse.error = error.debugDescription
                callback(transloaditResponse)

            }
            
        }
        
        dataTask.resume()
    }
    */
}


extension String {

    func hmac(key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, self, self.count, &digest)
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
