import AgoraLyricsScore
import XCTest
@testable import Demo

final class KaraokeSessionTests: XCTestCase {
    private let song = SongCatalog.songs[0]
    private let access = KaraokeAccess(
        uid: 1234,
        channelName: "kl-test-channel",
        rtcToken: "007-rtc",
        mccToken: "007-mcc"
    )

    private var credentials: AgoraCredentials {
        try! AgoraCredentials(
            appId: "0123456789abcdef0123456789abcdef",
            appCertificate: "fedcba9876543210fedcba9876543210"
        )
    }

    func testSessionRunsThroughPlaybackAndStopsIdempotently() {
        let client = FakeKaraokeClient()
        let session = KaraokeSession(client: client, tokenProvider: FakeTokenProvider(result: .success(access)))
        let delegate = FakeSessionDelegate()
        session.delegate = delegate

        session.start(song: song, credentials: credentials)
        XCTAssertEqual(session.state, .preparing(song))
        XCTAssertEqual(client.preparedSong, song)

        let lyrics = makeLyrics()
        client.emitLyrics(lyrics)
        XCTAssertEqual(session.state, .ready(song))
        XCTAssertTrue(delegate.lyrics === lyrics)

        client.emitStarted()
        XCTAssertEqual(session.state, .playing(song))

        session.pause()
        XCTAssertEqual(session.state, .paused(song))
        XCTAssertEqual(client.pauseCount, 1)

        session.resume()
        XCTAssertEqual(session.state, .playing(song))
        XCTAssertEqual(client.resumeCount, 1)

        session.stop()
        session.stop()
        XCTAssertEqual(session.state, .idle)
        XCTAssertEqual(client.cleanupCount, 1)
    }

    func testSessionForwardsProgressPitchAndControls() {
        let client = FakeKaraokeClient()
        let session = KaraokeSession(client: client, tokenProvider: FakeTokenProvider(result: .success(access)))
        let delegate = FakeSessionDelegate()
        session.delegate = delegate
        session.start(song: song, credentials: credentials)

        client.emitProgress(1200)
        client.emitPitch(64.5)
        session.seek(milliseconds: 4000)
        session.toggleAudioTrack()

        XCTAssertEqual(delegate.progress, 1200)
        XCTAssertEqual(delegate.pitch, 64.5)
        XCTAssertEqual(client.seekPosition, 4000)
        XCTAssertEqual(client.toggleCount, 1)
    }

    func testTokenFailureMovesSessionToCredentialsFailure() {
        let client = FakeKaraokeClient()
        let session = KaraokeSession(
            client: client,
            tokenProvider: FakeTokenProvider(result: .failure(TokenProviderError.generationFailed))
        )

        session.start(song: song, credentials: credentials)

        XCTAssertEqual(session.state, .failed(song, .credentials))
        XCTAssertNil(client.preparedSong)
        XCTAssertEqual(client.cleanupCount, 0)
    }

    func testClientFailureAndFinishCleanUpOnce() {
        let failingClient = FakeKaraokeClient()
        let failingSession = KaraokeSession(
            client: failingClient,
            tokenProvider: FakeTokenProvider(result: .success(access))
        )
        failingSession.start(song: song, credentials: credentials)
        failingClient.emitFailure(.network)
        failingSession.stop()

        XCTAssertEqual(failingSession.state, .idle)
        XCTAssertEqual(failingClient.cleanupCount, 1)

        let finishingClient = FakeKaraokeClient()
        let finishingSession = KaraokeSession(
            client: finishingClient,
            tokenProvider: FakeTokenProvider(result: .success(access))
        )
        finishingSession.start(song: song, credentials: credentials)
        finishingClient.emitFinished()

        XCTAssertEqual(finishingSession.state, .finished(song))
        XCTAssertEqual(finishingClient.cleanupCount, 1)
    }

    private func makeLyrics() -> LyricModel {
        LyricModel(
            name: song.name,
            singer: "",
            lyricsType: .xml,
            lines: [],
            preludeEndPosition: 0,
            duration: 10_000,
            hasPitch: true
        )
    }
}

private final class FakeTokenProvider: TokenProviding {
    let result: Result<KaraokeAccess, Error>

    init(result: Result<KaraokeAccess, Error>) {
        self.result = result
    }

    func makeAccess(credentials: AgoraCredentials) throws -> KaraokeAccess {
        try result.get()
    }
}

private final class FakeKaraokeClient: KaraokeClientProtocol {
    weak var delegate: KaraokeClientDelegate?
    var preparedSong: Song?
    var pauseCount = 0
    var resumeCount = 0
    var seekPosition: Int?
    var toggleCount = 0
    var cleanupCount = 0

    func prepare(song: Song, credentials: AgoraCredentials, access: KaraokeAccess) {
        preparedSong = song
    }

    func pause() { pauseCount += 1 }
    func resume() { resumeCount += 1 }
    func seek(milliseconds: Int) { seekPosition = milliseconds }
    func toggleAudioTrack() { toggleCount += 1 }
    func cleanup() { cleanupCount += 1 }

    func emitLyrics(_ lyrics: LyricModel) { delegate?.client(self, didLoad: lyrics) }
    func emitStarted() { delegate?.clientDidStartPlayback(self) }
    func emitProgress(_ milliseconds: Int) { delegate?.client(self, didUpdateProgress: milliseconds) }
    func emitPitch(_ pitch: Double) { delegate?.client(self, didUpdatePitch: pitch) }
    func emitFailure(_ error: KaraokeError) { delegate?.client(self, didFail: error) }
    func emitFinished() { delegate?.clientDidFinishPlayback(self) }
}

private final class FakeSessionDelegate: KaraokeSessionDelegate {
    var states: [KaraokeSessionState] = []
    var lyrics: LyricModel?
    var progress: Int?
    var pitch: Double?

    func session(_ session: KaraokeSessionControlling, didChange state: KaraokeSessionState) {
        states.append(state)
    }

    func session(_ session: KaraokeSessionControlling, didLoad lyrics: LyricModel) {
        self.lyrics = lyrics
    }

    func session(_ session: KaraokeSessionControlling, didUpdateProgress milliseconds: Int) {
        progress = milliseconds
    }

    func session(_ session: KaraokeSessionControlling, didUpdatePitch pitch: Double) {
        self.pitch = pitch
    }
}
