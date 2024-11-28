//
//  SessionCopyTests.swift
//  TransloaditKit
//
//  Created by Donny Wals on 28/11/2024.
//

import XCTest
import Foundation
@testable import TransloaditKit

class SessionCopyTests: XCTestCase {
    let expectedTUSClientConfigIdentifier = "com.transloadit.tus.bg"
    let expectedTransloaditConfigIdentifier = "com.transloadit.bg"
    let transloaditConfigIdentifierForTesting = "com.transloadit.bg1"
    
    // @Test("Default session should not use an identifier when copying")
    func test_defaultSessionIgnoresIdentifierWhenCopyingSession() async throws {
        let session = URLSessionConfiguration.default
        XCTAssert(session.identifier == nil)
        let copy = session.copy(withIdentifier: "testIdentifier")
        XCTAssert(copy.identifier == nil)
    }
    
    // @Test("Background session should use an identifier when copying")
    func test_backgroundSessionUsesIdentifierWhenCopyingSession() async throws {
        let session = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
        XCTAssert(session.identifier == transloaditConfigIdentifierForTesting)
        let copy = session.copy(withIdentifier: "com.transloadit.bg2")
        XCTAssert(copy.identifier == "com.transloadit.bg2")
    }
    
    // @Test("TransloaditKit should use provided configuration")
    func test_transloaditKitShouldUseProvidedConfig() async throws {
        let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
        let transloadit = Transloadit(
            credentials: .init(key: "", secret: ""),
            sessionConfiguration: config)
        XCTAssert(transloadit.api.configuration.identifier == transloaditConfigIdentifierForTesting)
    }
    
    // @Test("TransloaditKit should make config copy when given a background URLSession")
    func test_transloaditKitShouldMakeConfigCopyForBackgroundURLSession() async throws {
        let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
        let session = URLSession(configuration: config)
        let transloadit = Transloadit(
            credentials: .init(key: "", secret: ""),
            session: session)
        XCTAssert(transloadit.api.configuration.identifier == expectedTransloaditConfigIdentifier)
    }
    
    // @Test("TUSClient should be given its own background configuration")
    func test_tusClientShouldMakeSessionCopy() async throws {
        let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
        let transloadit = Transloadit(
            credentials: .init(key: "", secret: ""),
            sessionConfiguration: config)
        XCTAssert(transloadit.tusSessionConfig.identifier == expectedTUSClientConfigIdentifier)
    }
    
    // @Test("TUSClient and TransloaditKit should have unique session configuration identifiers when providing a config")
    func test_tusAndTransloaditHaveUniqueIdentifiersWhenProvidingConfiguration() async throws {
        let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
        let transloadit = Transloadit(
            credentials: .init(key: "", secret: ""),
            sessionConfiguration: config)
        XCTAssert(transloadit.tusSessionConfig.identifier == expectedTUSClientConfigIdentifier)
        XCTAssert(transloadit.api.configuration.identifier == transloaditConfigIdentifierForTesting)
    }
    
    // @Test("TUSClient and TransloaditKit should have unique session configuration identifiers when providing a session")
    func test_tusAndTransloaditHaveUniqueIdentifiersWhenProvidingSession() async throws {
        let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
        let transloadit = Transloadit(
            credentials: .init(key: "", secret: ""),
            session: URLSession(configuration: config))
        XCTAssert(transloadit.tusSessionConfig.identifier == expectedTUSClientConfigIdentifier)
        XCTAssert(transloadit.api.configuration.identifier == expectedTransloaditConfigIdentifier)
    }
    
    // @Test("Checking session configurations should report correctly for background config")
    func test_transloaditReportsCorrectSessionTypesBGConfig() async throws {
        let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
        let transloadit = Transloadit(
            credentials: .init(key: "", secret: ""),
            sessionConfiguration: config)
        XCTAssert(transloadit.isUsingBackgroundConfiguration.transloadit)
        XCTAssert(transloadit.isUsingBackgroundConfiguration.tus)
    }
    
    // @Test("Checking session configurations should report correctly for default config")
    func test_transloaditReportsCorrectSessionTypesDefaultConfig() async throws {
        let config = URLSessionConfiguration.default
        let transloadit = Transloadit(
            credentials: .init(key: "", secret: ""),
            sessionConfiguration: config)
        XCTAssert(!transloadit.isUsingBackgroundConfiguration.transloadit)
        XCTAssert(!transloadit.isUsingBackgroundConfiguration.tus)
    }
}
