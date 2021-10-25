import TUSKit
import Foundation

public struct TransloaditError: Error {
    let code: Int
    
    public static let couldNotFetchStatus = TransloaditError(code: 1)
    // TODO: Add underlying error?
    public static let couldNotCreateAssembly = TransloaditError(code: 2)
    // TODO: Pass underlying error?
    public static let couldNotUploadFile = TransloaditError(code: 3)
}

public protocol TransloaditFileDelegate: AnyObject {
    
    func didStartUpload(assembly: Assembly, client: Transloadit)
    
    func didFinishUpload(assembly: Assembly, client: Transloadit)
    
    func progress(assembly: Assembly, bytedUploaded: Int, bytesTotal: Int, client: Transloadit)
    
    /// Any type of error, maybe files couldn't be cleaned up on start. For instance.
    func didError(error: Error, client: Transloadit)
}

    
public final class TransloaditPoller {
    
    weak var transloadIt: Transloadit?
    var assemblyURL: URL? {
        didSet {
            guard let newURL = assemblyURL else {
                return
            }

            checkAndStartPolling(url: newURL)
        }
    }
    
    let didFinish: () -> Void
    var completion: ((Result<AssemblyStatus, TransloaditError>) -> Void)?
    
    init(transloadit: Transloadit, didFinish: @escaping () -> Void) {
        self.transloadIt = transloadit
        self.didFinish = didFinish
    }
    
    public func pollAssemblyStatus(completion: @escaping (Result<AssemblyStatus, TransloaditError>) -> Void) {
        self.completion = completion
    }


    private func checkAndStartPolling(url: URL) {
        guard let completion = completion else {
            // No listener set, no need to poll
            return
        }

        pollStatus(assemblyURL: url, completion: completion)
    }
    
    /// Keep fetching status until tit's completed or if it fails.
    /// - Parameters:
    ///   - assemblyURL: The url to check for the status
    ///   - completion: Completion with the AssemblyStatus.
    private func pollStatus(assemblyURL: URL, completion: @escaping (Result<AssemblyStatus, TransloaditError>) -> Void) {
        // TODO: What to do when reference is lost
        guard let transloadIt = transloadIt else {
            assertionFailure("Transloadit reference is lost")
            return
        }

        transloadIt.fetchStatus(assemblyURL: assemblyURL) { [weak self] result in
            guard let self = self else {
                // TODO: What to do when reference is lost
                return
            }
            
            do {
                let status = try result.get()
                completion(result)
                
                if status.status == .completed || status.status == .canceled || status.status == .aborted {
                    self.didFinish()
                } else {
                    print("continuing poll")
                    // Call succeeded, but not the finished status
                    // TODO: Limit amount? Or timeout after?
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.pollStatus(assemblyURL: assemblyURL, completion: completion)
                    }
                }
            } catch {
                print("ENDING POLL ON CALL FAILURE \(result)")
                completion(result) // End on call failure
            }
        }
    }
    
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
    private let tusClient: TUSClient
    
    public weak var delegate: TransloaditFileDelegate?
    
    public init(credentials: Transloadit.Credentials, session: URLSession) {
        self.api = TransloaditAPI(credentials: credentials, session: session)
        
        // TODO: If you don't want to upload files, then someone doesn't have to set up a directory.
        // TODO: That also means that tus can be lazy because someone may not need it.
        
        // TODO: Mock network for testing?
        // TODO: Add config and storage dir
        self.tusClient = TUSClient(config: TUSConfig(server: URL(string:"https://api2-kishtw.transloadit.com/resumable/files/")!), sessionIdentifier: "TransloadIt", storageDirectory: nil, session: session)
        tusClient.delegate = self
    }
    
    /// Create an assembly, do not upload a file.
    /// - Parameter steps: The steps of an Assembly.
    /// - Parameter expectedNumberOfFiles: The number of expected files to upload to this assembly
    /// - Parameter completion: The created assembly
    public func createAssembly(steps: [Step], expectedNumberOfFiles: Int = 1, completion: @escaping (Result<Assembly, TransloaditError>) -> Void) {
        api.createAssembly(steps: steps, expectedNumberOfFiles: expectedNumberOfFiles) { result in
            let transloaditResult = result.mapError { _ in TransloaditError.couldNotCreateAssembly }
            completion(transloaditResult)
        }
    }
    
    // TODO: Support assembly creation without uploading a file
    // TODO: Add a waitstep to fetch status?
    // TODO: Add a wait step for uploaded file?
    /// Create an assembly and upload one or more files to it using the TUS protocol.
    /// - Parameters:
    ///   - steps: The steps of an assembly.
    ///   - files: The files to upload
    ///   - completion: completion handler, called when upload is complete
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
        
        print("TUS Starting upload")
        delegate?.didStartUpload(assembly: assembly, client: self)
    }
    
    public func didFinishUpload(id: UUID, url: URL, client: TUSClient) {
        print("TUS Finishing upload \(url)")
        guard let assembly = assemblies[id] else {
            assertionFailure("Could not retrieve assembly for file id: \(id)")
            return
        }
        delegate?.didFinishUpload(assembly: assembly, client: self)
    }
    
    public func fileError(error: TUSClientError, client: TUSClient) {
        print("TUS file error")
        delegate?.didError(error: error, client: self)
    }
    
    public func progressFor(id: UUID, bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        print("progress \(bytesUploaded) of \(totalBytes)")
    }
    
    public func totalProgress(bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        
    }

    
    public func uploadFailed(id: UUID, error: Error, client: TUSClient) {
        print("upload failed \(error)")
    }
}
