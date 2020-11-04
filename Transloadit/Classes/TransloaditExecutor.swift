//
//  TransloaditExecutor.swift
//  Transloadit
//
//  Created by Mark Robert Masterson on 10/25/20.
//

import Foundation
import CommonCrypto
import TUSKit

class TransloaditExecutor {
    // MARK: CRUD
    private var SECRET = ""
    private var KEY = ""
    
    internal init(withKey key: String, andSecret secret: String) {
        KEY = key
        SECRET = secret
    }
    
    private func generateBody(forAPIObject object: APIObject, includeSecret: Bool) -> Dictionary<String,String> {
        var steps: [String:Any] = [:]
        if (object.isKind(of: Assembly.self)) {
            steps = (object as! Assembly).steps
        } else if (object.isKind(of: Template.self)) {
        }
        
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "YYYY/MM/dd HH:mm:s+00:00"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let dateTime: String = formatter.string(from: Date().addingTimeInterval(300))
        let authObject = ["key": KEY, "expires": dateTime]
        
        let params = ["auth": authObject, "steps": steps]
        let paramsData: Data?
        if #available(iOS 13.0, *) {
            paramsData = try! JSONSerialization.data(withJSONObject: params, options:.withoutEscapingSlashes)
        } else {
            paramsData = try! JSONSerialization.data(withJSONObject: params, options: [])
        }
        let paramsJsonString = String(data: paramsData!, encoding: .utf8)
        
        
        return ["signature": paramsJsonString!.hmac(key: SECRET), "params": paramsJsonString!, "tus_num_expected_upload_files": "1"]
        
    }
        
    public func create(_ object: APIObject) {
        self.urlRequest(withMethod: "POST", andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
                    print(response.tusURL)
                    TUSClient.shared.uploadURL = URL(string: response.tusURL)
                    //TUSClient.shared.startOrResume(forUpload: (object as! Assembly).tusUpload!, withExisitingURL: "")
                    
                    
                    
                    let metadata = String(format: "%@ %@,%@ %@,%@ %@", "assembly_url", response.assemblyURL.data(using: .utf8)?.base64EncodedString() as! CVarArg,"filename","file".data(using: .utf8)?.base64EncodedString() as! CVarArg,"fieldname","file-input".data(using: .utf8)?.base64EncodedString() as! CVarArg)
                    
                    TUSClient.shared.createOrResume(forUpload: (object as! Assembly).tusUpload!, withCustomHeaders: ["Upload-Metadata":metadata])
                    Transloadit.shared.delegate?.transloaditAssemblyCreationResult()
                }
                if object.isKind(of: Template.self) {
                    Transloadit.shared.delegate?.transloaditTemplateCreationResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
                    Transloadit.shared.delegate?.transloaditAssemblyCreationError()
                }
                if object.isKind(of: Template.self) {
                    Transloadit.shared.delegate?.transloaditTemplateCreationError()
                }
            }
        })
    }
    
    public func get(_ object: APIObject) {
        self.urlRequest(withMethod: "GET", andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
                    Transloadit.shared.delegate?.transloaditAssemblyGetResult()
                }
                if object.isKind(of: Template.self) {
                    Transloadit.shared.delegate?.transloaditTemplateGetResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
                    Transloadit.shared.delegate?.transloaditAssemblyGetError()
                }
                if object.isKind(of: Template.self) {
                    Transloadit.shared.delegate?.transloaditTemplateGetError()
                }
            }
        })
    }
    
    public func update(_ object: APIObject) {
        self.urlRequest(withMethod: "PUT", andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
                    Transloadit.shared.delegate?.transloaditAssemblyGetResult()
                }
                if object.isKind(of: Template.self) {
                    Transloadit.shared.delegate?.transloaditTemplateGetResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
                    Transloadit.shared.delegate?.transloaditAssemblyGetError()
                }
                if object.isKind(of: Template.self) {
                    Transloadit.shared.delegate?.transloaditTemplateGetError()
                }
            }
        })
    }
    
    public func delete(_ object: APIObject) {
        self.urlRequest(withMethod: "DELETE", andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
                    Transloadit.shared.delegate?.transloaditAssemblyDeletionResult()
                }
                if object.isKind(of: Template.self) {
                    Transloadit.shared.delegate?.transloaditTemplateDeletionResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
                    Transloadit.shared.delegate?.transloaditAssemblyDeletionError()
                }
                if object.isKind(of: Template.self) {
                    Transloadit.shared.delegate?.transloaditTemplateDeletionError()
                }
            }
        })
    }
    
    // MARK: Assembly
    
    public func invokeAssembly() {
        
    }
    
    //MARK: PRIVATE
    
    // MARK: Networking
    
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
            var movieData = [String: Any]()

            guard let data = data, error == nil else { return }
            do {
                movieData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                var response = TransloaditResponse()
                response.tusURL = movieData["tus_url"]! as! String
                response.assemblyURL = movieData["assembly_ssl_url"]! as! String

                print("made it")
                callback(response)
            } catch let error as NSError {
                print(error)
            }
            //let outputStr  = String(data: data!, encoding: String.Encoding.utf8) as String!
           // print(outputStr)
            
            
        }
        
        dataTask.resume()
    }
    
    
}
