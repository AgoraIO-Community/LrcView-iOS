import AgoraLyricsScore
import XCTest
@testable import Demo

final class KaraokeViewControllerTests: XCTestCase {
    private let song = SongCatalog.songs[0]
    private let credentials = try! AgoraCredentials(
        appId: "0123456789abcdef0123456789abcdef",
        appCertificate: "fedcba9876543210fedcba9876543210"
    )

    func testGrantedPermissionStartsSessionOnlyOnce() {
        let session = FakeKaraokeSession()
        let controller = makeController(
            session: session,
            permission: FakeMicrophonePermission(state: .granted)
        )
        controller.loadViewIfNeeded()

        appear(controller)
        disappear(controller)
        appear(controller)

        XCTAssertEqual(session.startedSongs, [song])
        XCTAssertEqual(session.startedCredentials, [credentials])
    }

    func testUndeterminedPermissionRequestsAndStartsAfterGrant() {
        let session = FakeKaraokeSession()
        let permission = FakeMicrophonePermission(state: .undetermined, requestResult: .granted)
        let controller = makeController(session: session, permission: permission)
        controller.loadViewIfNeeded()

        appear(controller)

        XCTAssertEqual(permission.requestCount, 1)
        XCTAssertEqual(session.startedSongs, [song])
    }

    func testDeniedPermissionDoesNotStartAndShowsSettingsAction() {
        let session = FakeKaraokeSession()
        let controller = makeController(
            session: session,
            permission: FakeMicrophonePermission(state: .denied)
        )
        controller.loadViewIfNeeded()

        appear(controller)

        XCTAssertTrue(session.startedSongs.isEmpty)
        XCTAssertEqual(controller.contentView.messageLabel.text, "需要麦克风权限才能检测音高")
        XCTAssertFalse(controller.contentView.openSettingsButton.isHidden)
    }

    func testPauseButtonPausesAndThenResumesSession() {
        let session = FakeKaraokeSession(state: .playing(song))
        let controller = makeController(session: session)
        controller.loadViewIfNeeded()

        controller.contentView.pauseButton.sendActions(for: .touchUpInside)
        controller.contentView.pauseButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(session.pauseCount, 1)
        XCTAssertEqual(session.resumeCount, 1)
    }

    func testNextStopsSessionBeforeEmittingNextSong() {
        let session = FakeKaraokeSession()
        var selectedSong: Song?
        let controller = makeController(session: session) { selectedSong = $0 }
        controller.loadViewIfNeeded()

        controller.contentView.nextButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(session.stopCount, 1)
        XCTAssertEqual(selectedSong, SongCatalog.next(after: song))
    }

    func testViewWillDisappearStopsSession() {
        let session = FakeKaraokeSession()
        let controller = makeController(session: session)
        controller.loadViewIfNeeded()

        disappear(controller)

        XCTAssertEqual(session.stopCount, 1)
    }

    func testCancelledDisappearanceDoesNotStopSession() {
        let session = FakeKaraokeSession(state: .playing(song))
        let controller = makeController(session: session)

        controller.handleDisappearanceCompletion(wasCancelled: true)

        XCTAssertEqual(session.stopCount, 0)
        XCTAssertEqual(session.state, .playing(song))
    }

    func testSkipPreludeSeeksOneSecondBeforeFirstLyric() {
        let session = FakeKaraokeSession()
        let controller = makeController(session: session)
        controller.loadViewIfNeeded()
        controller.session(session, didLoad: makeLyrics(preludeEndPosition: 4_500))

        controller.contentView.skipPreludeButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(session.seekPositions, [3_500])
    }

    func testRetryStopsBeforeStartingTheSameSong() {
        let session = FakeKaraokeSession(state: .failed(song, .network))
        let controller = makeController(session: session)
        controller.loadViewIfNeeded()
        controller.session(session, didChange: .failed(song, .network))

        controller.contentView.retryButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(session.stopCount, 1)
        XCTAssertEqual(session.startedSongs, [song])
    }

    private func makeController(
        session: FakeKaraokeSession,
        permission: FakeMicrophonePermission = FakeMicrophonePermission(state: .granted),
        onNext: @escaping (Song) -> Void = { _ in }
    ) -> KaraokeViewController {
        let controller = KaraokeViewController(
            song: song,
            credentials: credentials,
            session: session,
            permissionProvider: permission,
            onNext: onNext,
            onBack: {}
        )
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()
        return controller
    }

    private func makeLyrics(preludeEndPosition: UInt) -> LyricModel {
        let tone = LyricToneModel(
            beginTime: preludeEndPosition,
            duration: 1_000,
            word: "十年",
            pitch: 60,
            lang: .zh,
            pronounce: ""
        )
        let line = LyricLineModel(
            beginTime: preludeEndPosition,
            duration: 1_000,
            content: "十年",
            tones: [tone]
        )
        return LyricModel(
            name: song.name,
            singer: "",
            lyricsType: .xml,
            lines: [line],
            preludeEndPosition: preludeEndPosition,
            duration: 10_000,
            hasPitch: true
        )
    }

    private func appear(_ controller: UIViewController) {
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
    }

    private func disappear(_ controller: UIViewController) {
        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
    }
}

private final class FakeMicrophonePermission: MicrophonePermissionProviding {
    var state: MicrophonePermissionState
    let requestResult: MicrophonePermissionState
    private(set) var requestCount = 0

    init(state: MicrophonePermissionState, requestResult: MicrophonePermissionState? = nil) {
        self.state = state
        self.requestResult = requestResult ?? state
    }

    func request(_ completion: @escaping (MicrophonePermissionState) -> Void) {
        requestCount += 1
        state = requestResult
        completion(requestResult)
    }
}

private final class FakeKaraokeSession: KaraokeSessionControlling {
    weak var delegate: KaraokeSessionDelegate?
    var state: KaraokeSessionState
    private(set) var startedSongs: [Song] = []
    private(set) var startedCredentials: [AgoraCredentials] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var seekPositions: [Int] = []
    private(set) var toggleCount = 0
    private(set) var stopCount = 0

    init(state: KaraokeSessionState = .idle) {
        self.state = state
    }

    func start(song: Song, credentials: AgoraCredentials) {
        startedSongs.append(song)
        startedCredentials.append(credentials)
        state = .preparing(song)
        delegate?.session(self, didChange: state)
    }

    func pause() {
        pauseCount += 1
        guard case let .playing(song) = state else { return }
        state = .paused(song)
        delegate?.session(self, didChange: state)
    }

    func resume() {
        resumeCount += 1
        guard case let .paused(song) = state else { return }
        state = .playing(song)
        delegate?.session(self, didChange: state)
    }

    func seek(milliseconds: Int) {
        seekPositions.append(milliseconds)
    }

    func toggleAudioTrack() {
        toggleCount += 1
    }

    func stop() {
        stopCount += 1
        state = .idle
        delegate?.session(self, didChange: state)
    }
}
