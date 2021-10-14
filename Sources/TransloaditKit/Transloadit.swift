import TUSKit
import Foundation

public struct TransloaditError: Error {
    
}

public protocol TransloaditDelegate: AnyObject {

    func didCreateAssembly(assembly: Assembly, client: Transloadit)
    
    func didStartUpload(assembly: Assembly, client: Transloadit)
    
    func didFinishUpload(assembly: Assembly, client: Transloadit)
    
    func progress(assembly: Assembly, bytedUploaded: Int, bytesTotal: Int, client: Transloadit)
    
    func didError(assembly: Assembly)
}

public final class Transloadit {
    
    public struct Credentials {
        let key: String
        let secret: String
        
        public init(key: String, secret: String) {
            self.key = key
            self.secret = secret
        }
    }
    
    private let api: TransloaditAPI
    private let tusClient: TUSClient
    
    public weak var delegate: TransloaditDelegate?
    
    public init(credentials: Transloadit.Credentials, session: URLSession) {
        self.api = TransloaditAPI(credentials: credentials, session: session)
        
        // TODO: Mock network for testing?
        // TODO: Add config and session and storage dir
        self.tusClient = TUSClient(config: TUSConfig(server: URL(string:"abc")!), sessionIdentifier: "TransloadIt", storageDirectory: nil)
        tusClient.delegate = self
    }
    
    public func createAssembly(steps: [Step], file: URL) {
        print("Creating assembly")
        api.createAssembly(steps: steps, file: file) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let assembly):
                self.delegate?.didCreateAssembly(assembly: assembly, client: self)
                do {
                    // TODO: Re-enable or mock out 
//                    try self.tusClient.uploadFileAt(filePath: file, uploadURL: assembly.tusURL)
                } catch {
                    assertionFailure("TODO: Handle error")
                }
            case .failure:
                assertionFailure("TODO: Handle error")
            }
        }
    }
    
}

extension Transloadit: TUSClientDelegate {
    public func didStartUpload(id: UUID, client: TUSClient) {
        
    }
    
    public func didFinishUpload(id: UUID, url: URL, client: TUSClient) {
        
    }
    
    public func fileError(error: TUSClientError, client: TUSClient) {
        
    }
    
    public func progressFor(id: UUID, bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        
    }
    
    public func totalProgress(bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        
    }

    
    public func uploadFailed(id: UUID, error: Error, client: TUSClient) {
        
    }
}

