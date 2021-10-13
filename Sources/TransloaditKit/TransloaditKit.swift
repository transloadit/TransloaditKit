import TUSKit
import Foundation

// Services overview
// https://transloadit.com/docs/transcoding/#document-convert
// https://transloadit.com/services/

public struct Step {
    let name: String
    let robot: String
    let options: [String: Any]
    
    public init(name: String, robot: String, options: [String: Any]) {
        self.name = name
        self.robot = robot
        self.options = options
    }
}


public struct TransloaditError: Error {
    
}

public final class Transloadit {
    
    private let config: [String: Any]
    
    public weak var delegate: TransloaditDelegate?
    
    public init(config: [String: Any], session: URLSession) {
        self.config = config
    }
    
    public func createAssembly(steps: [Step], file: URL) {
        print("Creating assembly")
        DispatchQueue.main.async {
            let assembly = Assembly(id: UUID(), status: .completed, statusCode: 200, error: nil, tusURL: "abc", assemblySSLURL: "def", bytesReceived: 200, bytesExpected: 200)
            self.delegate?.didCreateAssembly(assembly: assembly, client: self)
        }
    }
    
}

public protocol TransloaditDelegate: AnyObject {

    func didCreateAssembly(assembly: Assembly, client: Transloadit)
    
    func didStartUpload(assembly: Assembly, client: Transloadit)
    
    func didFinishUpload(assembly: Assembly, client: Transloadit)
    
    func progress(assembly: Assembly, bytedUploaded: Int, bytesTotal: Int, client: Transloadit)
    
    func didError(assembly: Assembly)
    
}

