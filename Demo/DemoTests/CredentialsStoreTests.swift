import XCTest
@testable import Demo

final class CredentialsStoreTests: XCTestCase {
    private var service = ""
    private var store: KeychainCredentialsStore!

    override func setUp() {
        super.setUp()
        service = "io.agora.KLyricsDemoTests.\(UUID().uuidString)"
        store = KeychainCredentialsStore(service: service)
    }

    override func tearDown() {
        try? store.clear()
        store = nil
        super.tearDown()
    }

    func testStoreStartsEmpty() throws {
        XCTAssertNil(try store.load())
    }

    func testSaveOverwriteAndClear() throws {
        let first = try AgoraCredentials(
            appId: "0123456789abcdef0123456789abcdef",
            appCertificate: "fedcba9876543210fedcba9876543210"
        )
        let second = try AgoraCredentials(
            appId: "fedcba9876543210fedcba9876543210",
            appCertificate: "0123456789abcdef0123456789abcdef"
        )

        try store.save(first)
        XCTAssertEqual(try store.load(), first)

        try store.save(second)
        XCTAssertEqual(try store.load(), second)

        try store.clear()
        XCTAssertNil(try store.load())
    }
}
