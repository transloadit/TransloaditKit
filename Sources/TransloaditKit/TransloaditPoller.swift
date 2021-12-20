import Foundation

enum TransloaditPollerError: Error {
    case noPollingURLAvailable
}

/// `TransloaditPoller` is returned by Transloadit when uploading files.
/// You can use the `pollAssemblyStatus` method to polling for a file status.
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
    
    private var isPolling = false
    private let didFinish: () -> Void
    
    private var completion: ((Result<AssemblyStatus, TransloaditError>) -> Void)?
    
    init(transloadit: Transloadit, didFinish: @escaping () -> Void) {
        self.transloadIt = transloadit
        self.didFinish = didFinish
    }
    
    /// After making an assembly and uploading files, you can use this method to fetch the assembly's status.
    /// - Parameter completion: Will pass a result containing the current status (or an error if status can't be fetched).
    public func pollAssemblyStatus(completion: @escaping (Result<AssemblyStatus, TransloaditError>) -> Void) {
        self.completion = completion
        if let assemblyURL = assemblyURL {
            checkAndStartPolling(url: assemblyURL)
        }
    }

#if compiler(>=5.5) && canImport(_Concurrency)
    @available(macOS 10.15, iOS 13, *)
    /// Async / Await alternative to wait for the processing to complete.
    /// Note that this will only return once the assembly is done processing (or failed).
    /// If you want intermediate statuses you can use `pollAssemblyStatus`.
    ///
    /// - Important: This method might run indefinitely if server doesn't respond.
    public func waitForProcessing() async throws {
        guard let assemblyURL = assemblyURL else {
            throw TransloaditPollerError.noPollingURLAvailable
        }
        // TODO: Timeout?
        
        return try await withCheckedThrowingContinuation { continuation in
            self.completion = { result in
                switch result {
                case .success(let status):
                    if status.processingStatus == .completed {
                        continuation.resume()
                    }
                case .failure(let statusError):
                    continuation.resume(throwing: statusError)
                }
            }
            checkAndStartPolling(url: assemblyURL)
        }
    }
#endif

    private func checkAndStartPolling(url: URL) {
        guard let completion = completion else {
            // No listener set, no need to poll
            return
        }
        
        guard !isPolling else { return }
        
        isPolling = true

        pollStatus(assemblyURL: url, completion: completion)
    }
    
    /// Keep fetching status until tit's completed or if it fails.
    /// - Parameters:
    ///   - assemblyURL: The url to check for the status
    ///   - completion: Completion with the AssemblyStatus.
    private func pollStatus(assemblyURL: URL, completion: @escaping (Result<AssemblyStatus, TransloaditError>) -> Void) {
        guard let transloadIt = transloadIt else {
            assertionFailure("Transloadit reference is lost")
            return
        }

        transloadIt.fetchStatus(assemblyURL: assemblyURL) { [weak self] result in
            guard let self = self else {
                return
            }
            
            do {
                let status = try result.get()
                completion(result)
                
                if status.processingStatus == .completed || status.processingStatus == .canceled || status.processingStatus == .aborted {
                    self.didFinish()
                } else {
                    // Call succeeded, but not the finished status
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.pollStatus(assemblyURL: assemblyURL, completion: completion)
                    }
                }
            } catch {
                completion(result) // End on call failure
            }
        }
    }
    
}
