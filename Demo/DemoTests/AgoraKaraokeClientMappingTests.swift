import AgoraRtcKit
import XCTest
@testable import Demo

final class AgoraKaraokeClientMappingTests: XCTestCase {
    private let song = SongCatalog.songs[0]
    private let credentials = try! AgoraCredentials(
        appId: "0123456789abcdef0123456789abcdef",
        appCertificate: "fedcba9876543210fedcba9876543210"
    )
    private let access = KaraokeAccess(
        uid: 1234,
        channelName: "kl-test-channel",
        rtcToken: "007-rtc",
        mccToken: "007-mcc"
    )

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

    func testMatchesOnlyTheCurrentRequestAndSong() {
        XCTAssertTrue(
            AgoraKaraokeClient.matchesCallback(
                requestId: "request-1",
                songCode: song.id,
                expectedRequestId: "request-1",
                currentSong: song
            )
        )
        XCTAssertFalse(
            AgoraKaraokeClient.matchesCallback(
                requestId: "stale-request",
                songCode: song.id,
                expectedRequestId: "request-1",
                currentSong: song
            )
        )
        XCTAssertFalse(
            AgoraKaraokeClient.matchesCallback(
                requestId: "request-1",
                songCode: SongCatalog.songs[1].id,
                expectedRequestId: "request-1",
                currentSong: song
            )
        )
    }

    func testPrepareResetsSDKSingletonsAndCleanupDestroysThem() {
        let lifecycle = FakeAgoraSDKLifecycle()
        let client = AgoraKaraokeClient(lifecycle: lifecycle)

        client.prepare(song: song, credentials: credentials, access: access)
        XCTAssertEqual(lifecycle.replaceCount, 1)

        client.cleanup()
        XCTAssertEqual(lifecycle.destroyCount, 1)
    }
}

private final class FakeAgoraSDKLifecycle: AgoraSDKLifecycleManaging {
    private(set) var replaceCount = 0
    private(set) var destroyCount = 0

    func replaceSharedInstances(then start: @escaping () -> Void) {
        replaceCount += 1
    }

    func destroySharedInstances() {
        destroyCount += 1
    }
}
