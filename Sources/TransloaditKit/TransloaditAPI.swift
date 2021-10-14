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
}

final class TransloaditAPI {
    
    let basePath = URL(string: "https://api2.transloadit.com")!
    
    enum Endpoint: String {
        case assemblies = "/assemblies"
    }
    
    let session: URLSession
    
    static let formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd HH:mm:s+00:00"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }()
    
    // TODO: Security
    let credentials: Transloadit.Credentials
    
    init(credentials: Transloadit.Credentials, session: URLSession) {
        self.credentials = credentials
        self.session = session
    }
    
    public func createAssembly(steps: [Step], file: URL, completion: @escaping((Result<Assembly, TransloaditError>) -> Void)) {
        DispatchQueue.main.async {
            try? self.makeRequest(steps: steps)
            let assembly = Assembly(id: "abc", tusURL: URL(string: "abc")!, assemblySSLURL: URL(string: "def")!)
//            let assembly = Assembly(id: UUID().uuidString, /* status: .completed, */ statusCode: 200, error: nil, tusURL: URL(string: "abc")!, assemblySSLURL: URL(string: "def")!, bytesReceived: 200, bytesExpected: 200)
            completion(.success(assembly))
        }
    }
    
    private func makeRequest(steps: [Step]) throws {
        
        func makeBody(includeSecret: Bool) throws -> [String: String] {
            // TODO: Why + 300?
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
            var body: [String: String] = ["params": paramsJSONString, "tus_num_expected_upload_files": "1"]
            if !credentials.secret.isEmpty {
                body["signature"] = paramsJSONString.hmac(key: credentials.secret)
            }
            
            print(body)
            
            return body
        }
        
        let boundary = UUID.init().uuidString
        
        func makeBodyData() throws -> Data {
            let formFields = try makeBody(includeSecret: true)
            var body: Data = Data()
            for field in formFields {
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
        
        let task = session.dataTask(with: request) { (data, response, error) in
    
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let assembly = try decoder.decode(Assembly.self, from: data)
                    print(assembly)
                } catch {
                    print(try? JSONSerialization.jsonObject(with: data, options: .allowFragments))

                    print(error)
                }
            }
            
        }
        
        task.resume()
                            
        
        
//        let dataTask = Transloadit.shared.transloaditSession.session.dataTask(with: request as URLRequest) { (data, response, error) in
//            var resonseData = [String: Any]()
    }
    
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
