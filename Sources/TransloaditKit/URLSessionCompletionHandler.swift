import Foundation

class URLSessionCompletionHandler {
  var data: Data
  let callback: (Result<(Data, URLResponse), Error>) -> Void

  init(callback: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
    self.callback = callback
    self.data = Data()
  }
}
