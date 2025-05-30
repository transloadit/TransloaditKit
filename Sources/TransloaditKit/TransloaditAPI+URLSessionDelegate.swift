import Foundation

extension TransloaditAPI: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let completionHandler = callbacks.get(for: task) else {
            return
        }
        
        defer { callbacks.remove(for: task) }
        
        if let error {
            completionHandler.callback(.failure(error))
            return
        }
        
        guard let response = task.response else {
            completionHandler.callback(.failure(TransloaditAPIError.incompleteServerResponse))
            return
        }
        
        completionHandler.callback(.success((completionHandler.data, response)))
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        callbacks.get(for: dataTask)?.data.append(data)
    }
}
