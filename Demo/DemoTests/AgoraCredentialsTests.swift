import XCTest
@testable import Demo

final class AgoraCredentialsTests: XCTestCase {
    func testCredentialsTrimAndAcceptThirtyTwoHexCharacters() throws {
        let credentials = try AgoraCredentials(
            appId: " 0123456789abcdef0123456789abcdef ",
            appCertificate: "fedcba9876543210fedcba9876543210\n"
        )

        XCTAssertEqual(credentials.appId, "0123456789abcdef0123456789abcdef")
        XCTAssertEqual(credentials.appCertificate, "fedcba9876543210fedcba9876543210")
    }

    func testCredentialsRejectMalformedValues() {
        XCTAssertThrowsError(
            try AgoraCredentials(appId: "short", appCertificate: "also-short")
        )
    }

    func testCredentialsRejectNonASCIIHexCharacters() {
        XCTAssertThrowsError(
            try AgoraCredentials(
                appId: "g123456789abcdef0123456789abcdef",
                appCertificate: "fedcba9876543210fedcba9876543210"
            )
        )
    }
}
