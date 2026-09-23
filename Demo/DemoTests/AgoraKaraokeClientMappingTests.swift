import AgoraRtcKit
import XCTest
@testable import Demo

final class AgoraKaraokeClientMappingTests: XCTestCase {
    func testMapsUnavailableSongError() {
        XCTAssertEqual(
            AgoraKaraokeClient.mapPreloadError(.errorPermissionAndResource),
            .songUnavailable
        )
    }

    func testMapsDownloadFailure() {
        XCTAssertEqual(AgoraKaraokeClient.mapDownloadFailure(), .lyrics)
    }

    func testPreservesPlayerErrorCode() {
        XCTAssertEqual(AgoraKaraokeClient.mapPlayerError(rawValue: 7), .playback(code: 7))
    }
}
