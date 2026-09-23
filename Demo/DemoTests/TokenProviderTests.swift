import XCTest
@testable import Demo

final class TokenProviderTests: XCTestCase {
    private var credentials: AgoraCredentials {
        try! AgoraCredentials(
            appId: "0123456789abcdef0123456789abcdef",
            appCertificate: "fedcba9876543210fedcba9876543210"
        )
    }

    func testCreatesRtcAndMccAccessToken2Values() throws {
        let provider = LocalTokenProvider(uid: { 1234 }, channel: { "kl-test-channel" })

        let access = try provider.makeAccess(credentials: credentials)

        XCTAssertEqual(access.uid, 1234)
        XCTAssertEqual(access.channelName, "kl-test-channel")
        XCTAssertTrue(access.rtcToken.hasPrefix("007"))
        XCTAssertTrue(access.mccToken.hasPrefix("007"))
        XCTAssertNotEqual(access.rtcToken, access.mccToken)
    }

    func testRejectsZeroUid() {
        let provider = LocalTokenProvider(uid: { 0 }, channel: { "kl-test-channel" })

        XCTAssertThrowsError(try provider.makeAccess(credentials: credentials)) { error in
            XCTAssertEqual(error as? TokenProviderError, .invalidSessionIdentity)
        }
    }

    func testRejectsEmptyChannel() {
        let provider = LocalTokenProvider(uid: { 1234 }, channel: { "" })

        XCTAssertThrowsError(try provider.makeAccess(credentials: credentials)) { error in
            XCTAssertEqual(error as? TokenProviderError, .invalidSessionIdentity)
        }
    }
}
