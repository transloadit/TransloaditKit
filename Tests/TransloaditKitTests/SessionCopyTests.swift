//
//  SessionCopyTests.swift
//  TransloaditKit
//
//  Created by Donny Wals on 28/11/2024.
//

import Testing
import Foundation
@testable import TransloaditKit

let expectedTUSClientConfigIdentifier = "com.transloadit.tus.bg"
let expectedTransloaditConfigIdentifier = "com.transloadit.bg"
let transloaditConfigIdentifierForTesting = "com.transloadit.bg1"

@Test("Default session should not use an identifier when copying")
func defaultSessionIgnoresIdentifierWhenCopyingSession() async throws {
    let session = URLSessionConfiguration.default
    #expect(session.identifier == nil)
    let copy = session.copy(withIdentifier: "testIdentifier")
    #expect(copy.identifier == nil)
}

@Test("Background session should use an identifier when copying")
func backgroundSessionUsesIdentifierWhenCopyingSession() async throws {
    let session = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
    #expect(session.identifier == transloaditConfigIdentifierForTesting)
    let copy = session.copy(withIdentifier: "com.transloadit.bg2")
    #expect(copy.identifier == "com.transloadit.bg2")
}

@Test("TransloaditKit should use provided configuration")
func transloaditKitShouldUseProvidedConfig() async throws {
    let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
    let transloadit = Transloadit(
        credentials: .init(key: "", secret: ""),
        sessionConfiguration: config)
    #expect(transloadit.api.configuration.identifier == transloaditConfigIdentifierForTesting)
}

@Test("TransloaditKit should make config copy when given a background URLSession")
func transloaditKitShouldMakeConfigCopyForBackgroundURLSession() async throws {
    let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
    let session = URLSession(configuration: config)
    let transloadit = Transloadit(
        credentials: .init(key: "", secret: ""),
        session: session)
    #expect(transloadit.api.configuration.identifier == expectedTransloaditConfigIdentifier)
}

@Test("TUSClient should be given its own background configuration")
func tusClientShouldMakeSessionCopy() async throws {
    let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
    let transloadit = Transloadit(
        credentials: .init(key: "", secret: ""),
        sessionConfiguration: config)
    #expect(transloadit.tusSessionConfig.identifier == expectedTUSClientConfigIdentifier)
}

@Test("TUSClient and TransloaditKit should have unique session configuration identifiers when providing a config")
func tusAndTransloaditHaveUniqueIdentifiersWhenProvidingConfiguration() async throws {
    let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
    let transloadit = Transloadit(
        credentials: .init(key: "", secret: ""),
        sessionConfiguration: config)
    #expect(transloadit.tusSessionConfig.identifier == expectedTUSClientConfigIdentifier)
    #expect(transloadit.api.configuration.identifier == transloaditConfigIdentifierForTesting)
}

@Test("TUSClient and TransloaditKit should have unique session configuration identifiers when providing a session")
func tusAndTransloaditHaveUniqueIdentifiersWhenProvidingSession() async throws {
    let config = URLSessionConfiguration.background(withIdentifier: transloaditConfigIdentifierForTesting)
    let transloadit = Transloadit(
        credentials: .init(key: "", secret: ""),
        session: URLSession(configuration: config))
    #expect(transloadit.tusSessionConfig.identifier == expectedTUSClientConfigIdentifier)
    #expect(transloadit.api.configuration.identifier == expectedTransloaditConfigIdentifier)
}
