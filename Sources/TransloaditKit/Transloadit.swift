import TUSKit
import Foundation

public struct TransloaditError: Error {
    let code: Int
    
    public static let couldNotFetchStatus = TransloaditError(code: 1)
    public static let couldNotCreateAssembly = TransloaditError(code: 2)
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


/// Use the `Transloadit` class to uploadi files using the underlying TUS protocol.
/// You can either create an Assembly by itself, or create an Assembly and  upload files to it right away.
///
/// To create an Assembly and without uploading files, please refer to `createAssembly(steps: completion)`
/// To create an Assembly and upload files and check the assembly status, use `createAssembly(steps: andUpload files: completion)`
///
/// To get granular feedback on file uploading and bytes, implement the `fileDelegate` property on `Transloadit`
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
        // TODO: Make url optional in TUS? or keep for status checks?
//            let basePath = URL(string: "https://api2.transloadit.com")!
        let tusClient = TUSClient(config: TUSConfig(server: URL(string:"https://www.transloadit.com")!), sessionIdentifier: "TransloadIt", storageDirectory: storageDir, session: session)
        tusClient.delegate = self
        return tusClient
    }()
    
    let session: URLSession
    
    public weak var fileDelegate: TransloaditFileDelegate?
    
    /// Initialize Transloadit
    /// - Parameters:
    ///   - credentials: The credentials with required key and secret.
    ///   - session: A URLSession to use.
    ///   - storageDir: A storagedirectory to use. Used by underlying TUSKit mechanism to store files. If left empty, no directory will be made when performing non-file related tasks, such as creating assemblies. However, if you start uploading files, then TUS will make a directory, whether one you specify or a default one in the documents directory.
    public init(credentials: Transloadit.Credentials, session: URLSession, storageDir: URL? = nil) {
        self.api = TransloaditAPI(credentials: credentials, session: session)
        self.session = session
        self.storageDir = storageDir
    }
    
    public func start() {
        tusClient.start()
    }
    
    /// Stop all running uploads
    public func stopUploads() {
        // TODO: Maybe call it stop() and make sure assemblies that are running, are also stopped.
        tusClient.stopAndCancelAll()
    }
    
    /// Create an assembly, do not upload a file.
    ///
    /// This is useful for when you want to import a file from a different source, such as a third party storage service.
    ///
    /// If you wish to upload a file and check for its processing status, please refer to ` public func createAssembly(steps: andUpload files: completion:)`
    ///
    /// - Parameter steps: The steps of an Assembly.
    /// - Parameter expectedNumberOfFiles: The number of expected files to upload to this assembly
    /// - Parameter completion: The created assembly
    public func createAssembly(steps: [Step], expectedNumberOfFiles: Int = 1, completion: @escaping (Result<Assembly, TransloaditError>) -> Void) {
        api.createAssembly(steps: steps, expectedNumberOfFiles: expectedNumberOfFiles) { result in
            let transloaditResult = result.mapError { _ in TransloaditError.couldNotCreateAssembly }
            completion(transloaditResult)
        }
    }
    
    /// Create an assembly and upload one or more files to it using the TUS protocol.
    ///
    /// Returns a poller that you can use to check its processing status. You don't need to retain the poller, the `TransloadIt` instance will do that for you.
    ///
    /// TIP: You can set transloadit's `delegate` for details about the file uploading.
    /// - Parameters:
    ///   - steps: The steps of an assembly.
    ///   - files: Paths to the files to upload
    ///   - completion: completion handler, called when upload is complete
    ///
    /// Below you can see how you can create an assembly and poll for its upload status
    ///```swift
    ///
    ///       transloadit.createAssembly(steps: [resizeStep], andUpload: files, completion: { assemblyResult in
    ///           // received assembly response
    ///           print(assemblyResult)
    ///       }).pollAssemblyStatus { pollingResult in
    ///           // received polling status
    ///           print(pollingResult)
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
                                                         customHeaders: makeMetadata(assembly: assembly),
                                                         context: ["assembly": assembly.description])
                
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
    
    /// For unfinished uploads, schedule background tasks to upload them.
    /// iOS will decide per device when these tasks will be performed. E.g. with a wifi connection and late at night.
    
#if os(iOS)
    @available(iOS 13.0, *)
    public func scheduleBackgroundTasks() {
        tusClient.scheduleBackgroundTasks()
    }
#endif
}

extension Transloadit: TUSClientDelegate {
    
    public func didStartUpload(id: UUID, context: [String : String]?, client: TUSClient) {
        
        guard let context = context,
              let assemblyStr = context["assembly"],
              let assembly = Assembly(fromString: assemblyStr) else {
                  assertionFailure("Could not retrieve assembly for file id: \(id)")
                  return
        }
        
        fileDelegate?.didStartUpload(assembly: assembly, client: self)
    }
    
    public func didFinishUpload(id: UUID, url: URL, context: [String : String]?, client: TUSClient) {
        guard let context = context,
              let assemblyStr = context["assembly"],
              let assembly = Assembly(fromString: assemblyStr) else {
                  assertionFailure("Could not retrieve assembly for file id: \(id)")
                  return
        }

        fileDelegate?.didFinishUpload(assembly: assembly, client: self)
    }
    
    public func fileError(error: TUSClientError, client: TUSClient) {
        fileDelegate?.didError(error: error, client: self)
    }
    
    public func progressFor(id: UUID, bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        // TODO: Find assembly
//        guard let assembly = assemblies[id] else {
//            assertionFailure("Could not retrieve assembly for file id: \(id)")
//            return
//        }
//
        // TODO: Support bytes multiple uploads for one assembly
//        fileDelegate?.progressFor(assembly: assembly, bytesUploaded: bytesUploaded, totalBytes: totalBytes, client: self)
    }
    
    public func totalProgress(bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        fileDelegate?.totalProgress(bytesUploaded: bytesUploaded, totalBytes: totalBytes, client: self)
    }
    
    public func uploadFailed(id: UUID, error: Error, context: [String : String]?, client: TUSClient) {
        fileDelegate?.didError(error: error, client: self)
    }
}

