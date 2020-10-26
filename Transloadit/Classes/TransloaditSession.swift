//
//  TransloaditSession.swift
//  FBSnapshotTestCase
//
//  Created by Mark Robert Masterson on 10/25/20.
//

import Foundation

class TransloaditSession {
    var session: URLSession
    
    init() {
        //
        session = URLSession()
    }

    init(withDelegate delegate: URLSessionTaskDelegate) {
        session = URLSession(configuration: .default, delegate: delegate, delegateQueue: OperationQueue.main)
    }
    
    init(customConfiguration configuration: URLSessionConfiguration, andDelegate delegate: URLSessionTaskDelegate) {
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: OperationQueue.main)
    }
}
