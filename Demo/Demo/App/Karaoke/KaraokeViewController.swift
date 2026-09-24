import AgoraLyricsScore
import UIKit

final class KaraokeViewController: UIViewController, KaraokeDelegate {
    let song: Song
    let credentials: AgoraCredentials
    let session: KaraokeSessionControlling
    let permissionProvider: MicrophonePermissionProviding
    let onNext: (Song) -> Void
    let onBack: () -> Void
    let contentView = KaraokeContentView()

    private var lyrics: LyricModel?
    private var hasRequestedStart = false
    private var isOriginalTrackEnabled = false

    init(
        song: Song,
        credentials: AgoraCredentials,
        session: KaraokeSessionControlling,
        permissionProvider: MicrophonePermissionProviding,
        onNext: @escaping (Song) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.song = song
        self.credentials = credentials
        self.session = session
        self.permissionProvider = permissionProvider
        self.onNext = onNext
        self.onBack = onBack
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = song.name
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "伴奏",
            style: .plain,
            target: self,
            action: #selector(toggleAudioTrack)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = "切换原唱或伴奏"

        session.delegate = self
        contentView.karaokeView.delegate = self
        contentView.skipPreludeButton.addTarget(self, action: #selector(skipPrelude), for: .touchUpInside)
        contentView.pauseButton.addTarget(self, action: #selector(togglePause), for: .touchUpInside)
        contentView.nextButton.addTarget(self, action: #selector(nextSong), for: .touchUpInside)
        contentView.retryButton.addTarget(self, action: #selector(retry), for: .touchUpInside)
        contentView.backButton.addTarget(self, action: #selector(backToSongs), for: .touchUpInside)
        contentView.openSettingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        render(session.state)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasRequestedStart else { return }
        hasRequestedStart = true
        requestPermissionAndStart()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let transitionCoordinator else {
            handleDisappearanceCompletion(wasCancelled: false)
            return
        }
        let registered = transitionCoordinator.animate(alongsideTransition: nil) { [weak self] context in
            self?.handleDisappearanceCompletion(wasCancelled: context.isCancelled)
        }
        if !registered {
            handleDisappearanceCompletion(wasCancelled: false)
        }
    }

    func handleDisappearanceCompletion(wasCancelled: Bool) {
        if !wasCancelled {
            session.stop()
        }
    }

    private func requestPermissionAndStart() {
        switch permissionProvider.state {
        case .granted:
            startSession()
        case .denied:
            showMicrophoneDenied()
        case .undetermined:
            contentView.showLoading(message: "正在请求麦克风权限")
            permissionProvider.request { [weak self] state in
                guard let self else { return }
                if state == .granted {
                    self.startSession()
                } else {
                    self.showMicrophoneDenied()
                }
            }
        }
    }

    private func startSession() {
        contentView.showLoading(message: "正在准备歌曲")
        session.start(song: song, credentials: credentials)
    }

    private func showMicrophoneDenied() {
        contentView.showError(
            message: "需要麦克风权限才能检测音高",
            recovery: .systemSettings
        )
    }

    private func render(_ state: KaraokeSessionState) {
        switch state {
        case .idle:
            contentView.hideOverlay()
            contentView.setPaused(false)
        case .preparing:
            contentView.showLoading(message: "正在准备歌曲")
        case .ready:
            contentView.showLoading(message: "正在开始播放")
        case .playing:
            contentView.hideOverlay()
            contentView.setPaused(false)
        case .paused:
            contentView.hideOverlay()
            contentView.setPaused(true)
        case .finished:
            contentView.hideOverlay()
            contentView.setPaused(false)
        case let .failed(_, error):
            contentView.showError(message: error.message, recovery: error.recovery)
        }
    }

    @objc private func skipPrelude() {
        guard let lyrics else { return }
        session.seek(milliseconds: max(Int(lyrics.preludeEndPosition) - 1_000, 0))
    }

    @objc private func togglePause() {
        if case .paused = session.state {
            session.resume()
        } else if case .playing = session.state {
            session.pause()
        }
    }

    @objc private func nextSong() {
        session.stop()
        onNext(SongCatalog.next(after: song))
    }

    @objc private func retry() {
        session.stop()
        startSession()
    }

    @objc private func backToSongs() {
        session.stop()
        onBack()
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func toggleAudioTrack() {
        session.toggleAudioTrack()
        isOriginalTrackEnabled.toggle()
        navigationItem.rightBarButtonItem?.title = isOriginalTrackEnabled ? "原唱" : "伴奏"
    }

    func onKaraokeView(
        view: KaraokeView,
        didFinishLineWith model: LyricLineModel,
        score: Int,
        cumulativeScore: Int,
        lineIndex: Int,
        lineCount: Int
    ) {
        contentView.lineScoreLabel.text = "本句 \(score)"
        contentView.totalScoreLabel.text = "总分 \(cumulativeScore)"
    }
}

extension KaraokeViewController: KaraokeSessionDelegate {
    func session(_ session: KaraokeSessionControlling, didChange state: KaraokeSessionState) {
        render(state)
    }

    func session(_ session: KaraokeSessionControlling, didLoad lyrics: LyricModel) {
        self.lyrics = lyrics
        contentView.karaokeView.setLyricData(data: lyrics, usingInternalScoring: true)
    }

    func session(_ session: KaraokeSessionControlling, didUpdateProgress milliseconds: Int) {
        contentView.karaokeView.setProgress(progress: UInt(max(milliseconds, 0)))
    }

    func session(_ session: KaraokeSessionControlling, didUpdatePitch pitch: Double) {
        contentView.karaokeView.setPitch(speakerPitch: pitch, progressInMs: 0)
    }
}
