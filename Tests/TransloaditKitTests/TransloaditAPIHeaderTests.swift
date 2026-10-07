import Foundation
import XCTest
@testable import TransloaditKit

final class TransloaditAPIHeaderTests: XCTestCase {
    private var api: TransloaditAPI!
    private var expectedClientHeader = ""

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Check the transmitted version against release metadata to catch version drift.
        let repoURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let podspec = try String(contentsOf: repoURL.appendingPathComponent("Transloadit.podspec"), encoding: .utf8)
        let versionPattern = try NSRegularExpression(pattern: #"s\.version\s*=\s*['"]([^'"]+)['"]"#)
        let versionMatch = try XCTUnwrap(
            versionPattern.firstMatch(in: podspec, range: NSRange(location: 0, length: podspec.utf16.count)),
            "Transloadit.podspec must declare an SDK version"
        )
        let versionRange = try XCTUnwrap(Range(versionMatch.range(at: 1), in: podspec))
        expectedClientHeader = "transloaditkit:\(podspec[versionRange])"
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
            switch result {
            case .success(let receivedAssembly):
                XCTAssertEqual(receivedAssembly, assembly)
            case .failure(let error):
                XCTFail("Creating an assembly failed: \(error)")
            }
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
            switch result {
            case .success(let status):
                XCTAssertEqual(status.processingStatus, .completed)
            case .failure(let error):
                XCTFail("Fetching status failed: \(error)")
            }
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
            switch result {
            case .success(let status):
                XCTAssertEqual(status.processingStatus, .canceled)
            case .failure(let error):
                XCTFail("Canceling an assembly failed: \(error)")
            }
            completed.fulfill()
        }

        wait(for: [completed], timeout: 3)
    }

    private func prepareResponse(for url: URL, method: String, data: Data) {
        let expectedClientHeader = self.expectedClientHeader
        MockURLProtocol.prepareResponse(for: url, method: method) { headers in
            XCTAssertEqual(headers?["Transloadit-Client"], expectedClientHeader)
            // Session headers should survive adding SDK request headers on supported Apple platforms.
            XCTAssertEqual(headers?["X-Test-Header"], "preserved")
            if method == "POST" {
                XCTAssertTrue(headers?["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") == true)
            }
            return MockURLProtocol.Response(status: 200, headers: [:], data: data)
        }
    }
}
