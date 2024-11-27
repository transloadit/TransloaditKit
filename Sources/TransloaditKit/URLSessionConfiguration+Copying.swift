//
//  URLSessionConfiguration+Copying.swift
//  TransloaditKit
//
//  Created by Donny Wals on 27/11/2024.
//

import Foundation

extension URLSessionConfiguration {
    func copy(withIdentifier newIdentifier: String) -> URLSessionConfiguration {
        if let identifier = self.identifier {
            let copy = URLSessionConfiguration.background(withIdentifier: newIdentifier)
            copy.requestCachePolicy = requestCachePolicy
            copy.timeoutIntervalForRequest = timeoutIntervalForRequest
            copy.timeoutIntervalForResource = timeoutIntervalForResource
            copy.networkServiceType = networkServiceType
            copy.allowsCellularAccess = allowsCellularAccess
            copy.isDiscretionary = isDiscretionary
            copy.connectionProxyDictionary = connectionProxyDictionary
            copy.httpShouldUsePipelining = httpShouldUsePipelining
            copy.httpShouldSetCookies = httpShouldSetCookies
            copy.httpCookieAcceptPolicy = httpCookieAcceptPolicy
            copy.httpAdditionalHeaders = httpAdditionalHeaders
            copy.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
            copy.httpCookieStorage = httpCookieStorage
            copy.urlCredentialStorage = urlCredentialStorage
            copy.urlCache = urlCache
            copy.shouldUseExtendedBackgroundIdleMode = shouldUseExtendedBackgroundIdleMode
            copy.protocolClasses = protocolClasses
            return copy
        } else {
            return self.copy() as! URLSessionConfiguration
        }
    }
}
