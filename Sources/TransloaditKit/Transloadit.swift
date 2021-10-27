import TUSKit
import Foundation

public struct TransloaditError: Error {
    let code: Int
    
    public static let couldNotFetchStatus = TransloaditError(code: 1)
    // TODO: Add underlying error?
    public static let couldNotCreateAssembly = TransloaditError(code: 2)
    // TODO: Pass underlying error?
    public static let couldNotUploadFile = TransloaditError(code: 3)
    public static let couldNotClearCache = TransloaditError(code: 4)
}

public protocol TransloaditFileDelegate: AnyObject {
    
    func didStartUpload(assembly: Assembly, client: Transloadit)
    
    func didFinishUpload(assembly: Assembly, client: Transloadit)
    
    func progressFor(assembly: Assembly, bytesUploaded: Int, totalBytes: Int, client: Transloadit)
    
    /// Get the progress of all ongoing uploads combined
    ///
    /// - Important: The total is based on active uploads, so it will lower once files are uploaded. This is because it's ambiguous what the total is. E.g. You can be uploading 100 bytes, after 50 bytes are uploaded, let's say you add 150 more bytes, is the total then 250 or 200? And what if the upload is done, and you add 50 more. Is the total 50 or 300? or 250?
    ///
    /// As a rule of thumb: The total will be highest on the start, a good starting point is to compare the progress against that number.
    func totalProgress(bytesUploaded: Int, totalBytes: Int, client: Transloadit)
    
    /// Any type of error, maybe files couldn't be cleaned up on start. For instance.
    func didError(error: Error, client: Transloadit)
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
    
    typealias FileId = UUID
    /// A list of assemblies and its associated file ids
    var assemblies = [FileId: Assembly]()
    var pollers = [[URL]: TransloaditPoller]()
    
    private let api: TransloaditAPI
    private let storageDir: URL?
    
    lazy var tusClient: TUSClient = {
        // TODO: Make url optional in TUS?
//            let basePath = URL(string: "https://api2.transloadit.com")!
        let tusClient = TUSClient(config: TUSConfig(server: URL(string:"https://www.transloadit.com")!), sessionIdentifier: "TransloadIt", storageDirectory: storageDir, session: session)
        tusClient.delegate = self
        return tusClient
    }()
    
    let session: URLSession
    
    public weak var delegate: TransloaditFileDelegate?
    
    /// Initialize Transloadit
    /// - Parameters:
    ///   - credentials: The credentials with required key and secret.
    ///   - session: A URLSession to use.
    ///   - storageDir: A storagedirectory to use. Used by underlying TUSKit mechanism to store files. If left empty, no directory will be made when performing non-file related tasks, such as creating assemblies. However, if you start uploading files, then TUS will make a directory if you don't specify one.
    public init(credentials: Transloadit.Credentials, session: URLSession, storageDir: URL? = nil) {
        self.api = TransloaditAPI(credentials: credentials, session: session)
        self.session = session
        self.storageDir = storageDir
    }
    
    /// Create an assembly, do not upload a file.
    ///
    /// If you wish to upload a file and check for its processing status, please refer to ` public func createAssembly(steps: andUpload files: completion:)`
    /// - Parameter steps: The steps of an Assembly.
    /// - Parameter expectedNumberOfFiles: The number of expected files to upload to this assembly
    /// - Parameter completion: The created assembly
    public func createAssembly(steps: [Step], expectedNumberOfFiles: Int = 1, completion: @escaping (Result<Assembly, TransloaditError>) -> Void) {
        api.createAssembly(steps: steps, expectedNumberOfFiles: expectedNumberOfFiles) { result in
            let transloaditResult = result.mapError { _ in TransloaditError.couldNotCreateAssembly }
            completion(transloaditResult)
        }
    }
    
    /// Create an assembly and upload one or more files to it using the TUS protocol. You can use polling to check its processing status on TransloadIt servers.
    /// You can set the `delegate` for details about the file uploading.
    /// - Parameters:
    ///   - steps: The steps of an assembly.
    ///   - files: The files to upload
    ///   - completion: completion handler, called when upload is complete
    ///
    /// Below you can see how you can create an assembly and poll for its upload status
    ///```swift
    ///
    ///       transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { result in
    ///           // received assembly response
    ///       }).pollAssemblyStatus { result in
    ///           // received polling status
    ///       }
    ///```

    @discardableResult
    public func createAssembly(steps: [Step], andUpload files: [URL], completion: @escaping (Result<Assembly, TransloaditError>) -> Void)  -> TransloaditPoller {
        func makeMetadata(assembly: Assembly) -> [String: String] {
            ["fieldname": "file-input",
             "assembly_url": assembly.url.absoluteString,
             "filename": "file"]
        }
        
        let poller = TransloaditPoller(transloadit: self, didFinish: { [weak self] in
            guard let self = self else { return }
            self.pollers[files] = nil
        })
        
        if let existingPoller = self.pollers[files], existingPoller === poller {
            assertionFailure("Transloadit: Somehow already got a poller for this url and these files")
        }
        
        createAssembly(steps: steps, expectedNumberOfFiles: files.count, completion: { [weak self] result in
            guard let self = self else { return }
            
            do {
                let assembly = try result.get()
                let ids = try self.tusClient.uploadFiles(filePaths: files,
                                                         uploadURL: assembly.tusURL,
                                                         customHeaders: makeMetadata(assembly: assembly))
                
                for id in ids {
                    self.assemblies[id] = assembly
                }
                
                poller.assemblyURL = assembly.url
                
                completion(.success(assembly))
            } catch is TransloaditAPIError {
                completion(.failure(TransloaditError.couldNotCreateAssembly))
            } catch {
                completion(.failure(TransloaditError.couldNotUploadFile))
            }
        })
        
        
        pollers[files] = poller
        return poller
    }
    
    /// Stop all running uploads, reset local upload cache.
    /// - Throws: TransloaditError
    public func reset() throws {
        do {
            try tusClient.reset()
        } catch {
            throw TransloaditError.couldNotClearCache
        }
    }
    
    /// Retrieve the status of an Assembly.
    /// - Parameters:
    ///   - assemblyURL: The url to use
    ///   - completion: A handler that's called when the status fetching call is completed.
    public func fetchStatus(assemblyURL: URL, completion: @escaping (Result<AssemblyStatus, TransloaditError>) -> Void) {
        api.fetchStatus(assemblyURL: assemblyURL) { result in
            completion(result.mapError { _ in TransloaditError.couldNotFetchStatus })
        }
    }
    
}

extension Transloadit: TUSClientDelegate {
    public func didStartUpload(id: UUID, client: TUSClient) {
        guard let assembly = assemblies[id] else {
            assertionFailure("Could not retrieve assembly for file id: \(id)")
            return
        }
        
        delegate?.didStartUpload(assembly: assembly, client: self)
    }
    
    public func didFinishUpload(id: UUID, url: URL, client: TUSClient) {
        guard let assembly = assemblies[id] else {
            assertionFailure("Could not retrieve assembly for file id: \(id)")
            return
        }

        delegate?.didFinishUpload(assembly: assembly, client: self)
    }
    
    public func fileError(error: TUSClientError, client: TUSClient) {
        delegate?.didError(error: error, client: self)
    }
    
    public func progressFor(id: UUID, bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        guard let assembly = assemblies[id] else {
            assertionFailure("Could not retrieve assembly for file id: \(id)")
            return
        }
        
        // TODO: Support bytes multiple uploads for one assembly
        delegate?.progressFor(assembly: assembly, bytesUploaded: bytesUploaded, totalBytes: totalBytes, client: self)
    }
    
    public func totalProgress(bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        delegate?.totalProgress(bytesUploaded: bytesUploaded, totalBytes: totalBytes, client: self)
    }
    
    public func uploadFailed(id: UUID, error: Error, client: TUSClient) {
        delegate?.didError(error: error, client: self)
    }
}
