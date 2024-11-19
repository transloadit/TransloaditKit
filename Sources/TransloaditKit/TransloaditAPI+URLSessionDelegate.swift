import Foundation

extension TransloaditAPI: URLSessionDelegate {
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let callback = callbacks[task]?.1 else { 
      return
    }

    if let error {
      callback(.failure(error))
      return
    }
    
    guard let data = callbacks[task]?.0, let response = task.response else {
      //callback(.failure(TransloaditAPIError.unknown))
      return
    }

    callback(.success((data, response)))
  }

  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    callbacks[dataTask]?.0?.append(data)
  }
}
