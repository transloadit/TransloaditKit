import Foundation

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
    
    public func pollAssemblyStatus(completion: @escaping (Result<AssemblyStatus, TransloaditError>) -> Void) {
        self.completion = completion
        if let assemblyURL = assemblyURL {
            checkAndStartPolling(url: assemblyURL)
        }
    }


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
                
                if status.status == .completed || status.status == .canceled || status.status == .aborted {
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
