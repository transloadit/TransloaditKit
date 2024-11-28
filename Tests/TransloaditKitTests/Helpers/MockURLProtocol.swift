//
//  TUSMockDelegate.swift
//
//
//  Created by Tjeerd in ‘t Veen on 28/09/2021.
//

import Foundation
import TUSKit
import XCTest

/// TUSClientDelegate to support testing
final class TUSMockDelegate: TUSClientDelegate {
    
    var startedUploads = [UUID]()
    var finishedUploads = [(UUID, URL)]()
    var failedUploads = [(UUID, Error)]()
    var fileErrors = [TUSClientError]()
    var progressPerId = [UUID: Int]()
    var totalProgressReceived = [Int]()
    
    var activityCount: Int { finishedUploads.count + startedUploads.count + failedUploads.count + fileErrors.count }
    
    var finishUploadExpectation: XCTestExpectation?
    var startUploadExpectation: XCTestExpectation?
    var fileErrorExpectation: XCTestExpectation?
    var uploadFailedExpectation: XCTestExpectation?
    
    var receivedContexts = [[String: String]]()
    
    func didStartUpload(id: UUID, context: [String : String]?, client: TUSClient) {
        startedUploads.append(id)
        startUploadExpectation?.fulfill()
        
        if let context = context {
            receivedContexts.append(context)
        }
    }

    func didFinishUpload(id: UUID, url: URL, context: [String : String]?, client: TUSClient) {
        finishedUploads.append((id, url))
        finishUploadExpectation?.fulfill()
        if let context = context {
            receivedContexts.append(context)
        }
    }
    
    func fileError(error: TUSClientError, client: TUSClient) {
        fileErrors.append(error)
        fileErrorExpectation?.fulfill()
    }
    
    func uploadFailed(id: UUID, error: Error, context: [String : String]?, client: TUSClient) {
        failedUploads.append((id, error))
        uploadFailedExpectation?.fulfill()
        if let context = context {
            receivedContexts.append(context)
        }
    }
    
    func totalProgress(bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        totalProgressReceived.append(bytesUploaded)
    }
    
    func progressFor(id: UUID, context: [String: String]?, bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        progressPerId[id] = bytesUploaded
    }
}

struct PreparedResponseEndpoint: Hashable {
    let url: URL
    let method: String
}

/// MockURLProtocol to support mocking the network
final class MockURLProtocol: URLProtocol {
    
    typealias Headers = [String: String]?
    
    static let queue = DispatchQueue(label: "com.transloadit")
    
    struct Response {
        let status: Int
        let headers: [String: String]
        let data: Data?
    }
    
    static var responses = [PreparedResponseEndpoint: (Headers) -> Response]()
    static var receivedRequests = [URLRequest]()
    
    static func reset() {
        queue.async {
            responses = [:]
            receivedRequests = []
        }
    }
    
    /// Define a response to be used for a method
    /// - Parameters:
    ///   - method: The http method (POST PATCH etc)
    ///   - makeResponse: A closure that returns a Response
    static func prepareResponse(for url: URL, method: String, makeResponse: @escaping (Headers) -> Response) {
        queue.async {
            let prepResponseEndpoint = PreparedResponseEndpoint(url: url, method: method)
            responses[prepResponseEndpoint] = makeResponse
        }
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        // To check if this protocol can handle the given request.
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Here you return the canonical version of the request but most of the time you pass the orignal one.
        return request
    }
    
    override func startLoading() {
        Self.queue.async {
            guard let client = self.client else { return }
            guard let requestURL = self.request.url, let method = self.request.httpMethod else {
                return }
            
            let endpoint = PreparedResponseEndpoint(url: requestURL, method: method)
            guard let preparedResponseClosure = type(of: self).responses[endpoint] else {
                assertionFailure("No response found for endpoint \(endpoint) method \n request URL: \(String(describing: self.request.url)) \n prepared \(type(of: self).responses)")
                return
            }
            
            let preparedResponse = preparedResponseClosure(self.request.allHTTPHeaderFields)
            
            type(of: self).receivedRequests.append(self.request)
            
            let url = URL(string: "https://api2.transloadit.com")!
            let response = HTTPURLResponse(url: url, statusCode: preparedResponse.status, httpVersion: nil, headerFields: preparedResponse.headers)!
            
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            if let data = preparedResponse.data {
                client.urlProtocol(self, didLoad: data)
            }
            client.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
        // This is called if the request gets canceled or completed.
    }
}
