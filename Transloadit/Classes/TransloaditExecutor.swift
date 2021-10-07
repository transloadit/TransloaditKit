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
    private var timer: Timer?
    
    let tusClient: TUSClient
    
    internal init(withKey key: String, andSecret secret: String) {
        KEY = key
        SECRET = secret
        tusClient = TUSClient(config: TUSConfig(server: URL(string: "https://tusd.tusdemo.net/files")!), sessionIdentifier: "TransloadItKit", storageDirectory: nil)
        tusClient.delegate = self
        tusClient.start()
    }
    
    private func generateBody(forAPIObject object: APIObject, includeSecret: Bool) -> Dictionary<String,String> {
        var steps: NSMutableDictionary = [:]
        if (object.isKind(of: Assembly.self)) {
            steps = (object as! Assembly).steps
        } else if (object.isKind(of: Template.self)) {
        }
        
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "YYYY/MM/dd HH:mm:s+00:00"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let dateTime: String = formatter.string(from: Date().addingTimeInterval(300))
        let authObject = ["key": KEY, "expires": dateTime]
        
        let paramsOg = ["auth": authObject, "steps": steps] as [String : Any]
        let params = paramsOg.merging((object as! Assembly).custom as! [String : Any]) { (current, _) in current }
        let paramsData: Data?
        if #available(iOS 13.0, *) {
            paramsData = try! JSONSerialization.data(withJSONObject: params, options:.withoutEscapingSlashes)
        } else {
            paramsData = try! JSONSerialization.data(withJSONObject: params, options: [])
        }
        let paramsJsonString = String(data: paramsData!, encoding: .utf8)
        var response = ["params": paramsJsonString!, "tus_num_expected_upload_files": "1"]
        
        if (!SECRET.isEmpty) {
            response["signature"] = paramsJsonString!.hmac(key: SECRET)
        }
        return response
    }
    
    public func create(_ object: APIObject) {
        self.urlRequest(withMethod: "POST", andObject: object, callback: { [weak tusClient] response in
            if (response.success) {
                guard let tusClient = tusClient else {
                    return
                }
                
                guard let assembly = object as? Assembly else {
                    assertionFailure("Only assemblies are supported")
                    return
                }
                
                guard let filePath = assembly.filePath else {
                    assertionFailure("Assembly passed without a file path")
                    return
                }
                
                Transloadit.shared.delegate?.transloaditCreation(forObject: assembly, withResult: response)
//                TUSClient.shared.uploadURL = URL(string: response.tusURL)! // TODO Update URL?
                //TUSClient.shared.startOrResume(forUpload: (object as! Assembly).tusUpload!, withExisitingURL: "")
                let metaData = ["fieldname": "file-input",
                                     "assembly_url": response.assemblyURL,
                                     "filename": "file"]
                assembly.metaData = metaData
                assembly.assemblyURL = response.assemblyURL
                self.assemblyStatus(forAssembly: assembly)
                guard let uploadURL = URL(string: response.tusURL) else {
                    // TODO: Make real error
                    assertionFailure("No URL retrieved")
                    return
                }
                
                
                // TODO: Figure out why tusURL isn't working for create call.
                
                // TODO: Maybe skip straight to uploading?
                
                
                do {
                    try tusClient.uploadFileAt(filePath: filePath, uploadURL: uploadURL, customHeaders: metaData)
                } catch {
                    assertionFailure("Error \(error) for \(filePath)")
                }

            } else {
                if object.isKind(of: Assembly.self) {
                    Transloadit.shared.delegate?.transloaditCreation(forObject: object as! Assembly, withResult: response)
                }
                if object.isKind(of: Template.self) {
//                    Transloadit.shared.delegate?.transloaditTemplateCreationError()
                }
//                Transloadit.shared.delegate?.transloaditCreationResult(forObject: object)

            }
            Transloadit.shared.delegate?.transloaditCreation(forObject: object, withResult: response)

        })
    }
    
    public func get(_ object: APIObject) {
        self.urlRequest(withMethod: "GET", andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
//                    Transloadit.shared.delegate?.transloaditGetResult(forObject: object)
                }
                if object.isKind(of: Template.self) {
//                    Transloadit.shared.delegate?.transloaditTemplateGetResult()
                }
//                Transloadit.shared.delegate?.transloaditGetResult(forObject: object, withResult: response)
            } else {
                if object.isKind(of: Assembly.self) {
//                    Transloadit.shared.delegate?.transloaditGetResult(forObject: object)
                }
                if object.isKind(of: Template.self) {
//                    Transloadit.shared.delegate?.transloaditTemplateGetError()
                }
//                Transloadit.shared.delegate?.transloaditGetResult(forObject: object)

            }
            Transloadit.shared.delegate?.transloaditGet(forObject: object, withResult: response)

        })
    }
    
    public func update(_ object: APIObject) {
        self.urlRequest(withMethod: "PUT", andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
//                    Transloadit.shared.delegate?.transloaditAssemblyGetResult()
                }
                if object.isKind(of: Template.self) {
//                    Transloadit.shared.delegate?.transloaditTemplateGetResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
//                    Transloadit.shared.delegate?.transloaditAssemblyGetError()
                }
                if object.isKind(of: Template.self) {
//                    Transloadit.shared.delegate?.transloaditTemplateGetError()
                }
            }
            Transloadit.shared.delegate?.transloaditGet(forObject: object, withResult: response)
        })
    }
    
    public func delete(_ object: APIObject) {
        self.urlRequest(withMethod: "DELETE", andObject: object, callback: { response in
            if (response.success) {
                if object.isKind(of: Assembly.self) {
//                    Transloadit.shared.delegate?.transloaditAssemblyDeletionResult()
                }
                if object.isKind(of: Template.self) {
//                    Transloadit.shared.delegate?.transloaditTemplateDeletionResult()
                }
            } else {
                if object.isKind(of: Assembly.self) {
//                    Transloadit.shared.delegate?.transloaditAssemblyDeletionError()
                }
                if object.isKind(of: Template.self) {
//                    Transloadit.shared.delegate?.transloaditTemplateDeletionError()
                }
            }
            Transloadit.shared.delegate?.transloaditDeletion(forObject: object, withResult: response)
        })
    }
    
    // MARK: Assembly
    
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
    
    //MARK: TUS Delegate
    
//    func TUSProgress(bytesUploaded uploaded: Int, bytesRemaining remaining: Int) {
//        //
//        Transloadit.shared.delegate?.tranloaditUploadProgress(bytesUploaded: uploaded, bytesRemaining: remaining)
//    }
//
//    func TUSProgress(forUpload upload: TUSUpload, bytesUploaded uploaded: Int, bytesRemaining remaining: Int) {
//        //
//    }
//
//    func TUSSuccess(forUpload upload: TUSUpload) {
////        Transloadit.shared.delegate?.tranloaditUploadProgress(bytesUploaded: Int(upload.contentLength), bytesRemaining: Int(upload.contentLength))
//    }
//
//    func TUSFailure(forUpload upload: TUSUpload?, withResponse response: TUSResponse?, andError error: Error?) {
//        //
//        Transloadit.shared.delegate?.transloaditUploadFailure()
//    }
    
    
}

extension TransloaditExecutor: TUSClientDelegate {
    func totalProgress(progress: Float, client: TUSClient) {
    }
    
    func progressFor(id: UUID, progress: Float, client: TUSClient) {
    }
    
    public func didStartUpload(id: UUID, client: TUSClient) {
        print("TUSClient started upload, id is \(id)")
        print("TUSClient remaining is \(client.remainingUploads)")
    }
    
    public func didFinishUpload(id: UUID, url: URL, client: TUSClient) {
        print("TUSClient finished upload, id is \(id) url is \(url)")
        print("TUSClient remaining is \(client.remainingUploads)")
        if client.remainingUploads == 0 {
            print("Finished uploading")
        }
    }
    
    public func uploadFailed(id: UUID, error: Error, client: TUSClient) {
        print("TUSClient upload failed for \(id) error \(error)")
    }
    
    public func fileError(error: TUSClientError, client: TUSClient) {
        print("TUSClient File error \(error)")
        Transloadit.shared.delegate?.transloaditUploadFailure()
    }
}
