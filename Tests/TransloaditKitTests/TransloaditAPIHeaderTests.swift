import Foundation
import XCTest
@testable import TransloaditKit

final class TransloaditAPIHeaderTests: XCTestCase {
    private var api: TransloaditAPI!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.httpAdditionalHeaders = ["X-Test-Header": "preserved"]
        api = TransloaditAPI(
            credentials: .init(key: "test-key", secret: nil),
            sessionConfiguration: configuration,
            signatureGenerator: { _, completion in
                completion(.success("test-signature"))
            }
        )
    }

    override func tearDown() {
        api = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testCreateAssemblySendsClientHeader() {
        let assembly = Fixtures.makeAssembly()
        prepareResponse(
            for: URL(string: "https://api2.transloadit.com/assemblies")!,
            method: "POST",
            data: Fixtures.makeAssemblyResponse(assembly: assembly)
        )
        let completed = expectation(description: "Assembly created")

        api.createAssembly(steps: [], expectedNumberOfFiles: 0, customFields: [:]) { result in
            XCTAssertEqual(try result.get(), assembly)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
    }

    func testFetchStatusSendsClientHeader() {
        let assembly = Fixtures.makeAssembly()
        prepareResponse(
            for: assembly.url,
            method: "GET",
            data: Fixtures.makeAssemblyStatusResponse(assemblyStatus: Fixtures.makeAssemblyStatus(status: .completed))
        )
        let completed = expectation(description: "Status fetched")

        api.fetchStatus(assemblyURL: assembly.url) { result in
            XCTAssertEqual(try result.get().processingStatus, .completed)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
    }

    func testCancelAssemblySendsClientHeader() {
        let assembly = Fixtures.makeAssembly()
        prepareResponse(
            for: assembly.url,
            method: "DELETE",
            data: Fixtures.makeAssemblyStatusResponse(assemblyStatus: Fixtures.makeAssemblyStatus(status: .canceled))
        )
        let completed = expectation(description: "Assembly canceled")

        api.cancelAssembly(assembly) { result in
            XCTAssertEqual(try result.get().processingStatus, .canceled)
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
    }

    private func prepareResponse(for url: URL, method: String, data: Data) {
        MockURLProtocol.prepareResponse(for: url, method: method) { headers in
            XCTAssertEqual(headers?["Transloadit-Client"], "transloaditkit:3.5.0")
            XCTAssertEqual(headers?["X-Test-Header"], "preserved")
            if method == "POST" {
                XCTAssertTrue(headers?["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
            }
            return MockURLProtocol.Response(status: 200, headers: [:], data: data)
        }
    }
}
