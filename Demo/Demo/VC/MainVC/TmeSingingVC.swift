import UIKit
import AgoraLyricsScore

final class TmeSingingVC: UIViewController {
    private let song: TmeSong
    private let manager: TmeManager
    private let progressProvider = ProgressProvider()
    private let karaokeView = KaraokeView(frame: .zero)
    private let songLabel = UILabel()
    private let artistLabel = UILabel()
    private let playbackLabel = UILabel()
    private let lyricStatusLabel = UILabel()
    private let pitchStatusLabel = UILabel()
    private let fallbackLabel = UILabel()
    private let lineScoreLabel = UILabel()
    private let totalScoreLabel = UILabel()
    private let playPauseButton = UIButton(type: .system)
    private var hasModel = false
    private var playing = false
    private var progressStarted = false

    init(song: TmeSong, manager: TmeManager) {
        self.song = song
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "演唱"
        view.backgroundColor = .systemBackground
        progressProvider.delegate = self
        karaokeView.delegate = self
        karaokeView.lyricsView.inactiveLineTextColor = .secondaryLabel
        karaokeView.lyricsView.activeLineUpcomingTextColor = .label
        karaokeView.lyricsView.activeLinePlayedTextColor = .systemPink
        karaokeView.isHidden = true

        songLabel.text = song.name
        songLabel.font = .preferredFont(forTextStyle: .title2)
        songLabel.adjustsFontForContentSizeCategory = true
        songLabel.numberOfLines = 2
        artistLabel.text = song.artist
        artistLabel.textColor = .secondaryLabel
        artistLabel.font = .preferredFont(forTextStyle: .subheadline)
        artistLabel.numberOfLines = 2
        playbackLabel.text = "正在预加载歌曲"
        lyricStatusLabel.text = "歌词：等待下载"
        pitchStatusLabel.text = "Pitch：等待下载"
        fallbackLabel.text = "计分资料不可用，继续播放"
        fallbackLabel.textColor = .secondaryLabel
        fallbackLabel.isHidden = true
        lineScoreLabel.text = "本句  --"
        totalScoreLabel.text = "累计  0"
        totalScoreLabel.textColor = .systemGreen

        [playbackLabel, lyricStatusLabel, pitchStatusLabel, fallbackLabel,
         lineScoreLabel, totalScoreLabel].forEach {
            $0.font = .preferredFont(forTextStyle: .body)
            $0.adjustsFontForContentSizeCategory = true
            $0.numberOfLines = 0
        }
        let heading = UIStackView(arrangedSubviews: [songLabel, artistLabel, playbackLabel,
                                                       lyricStatusLabel, pitchStatusLabel])
        heading.axis = .vertical
        heading.spacing = 8
        let scores = UIStackView(arrangedSubviews: [lineScoreLabel, totalScoreLabel])
        scores.axis = .horizontal
        scores.distribution = .equalSpacing
        scores.isHidden = true
        let content = UIStackView(arrangedSubviews: [heading, fallbackLabel, karaokeView, scores])
        content.axis = .vertical
        content.spacing = 18
        view.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        karaokeView.translatesAutoresizingMaskIntoConstraints = false

        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playPauseButton.accessibilityLabel = "暂停播放"
        playPauseButton.isEnabled = false
        playPauseButton.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
        view.addSubview(playPauseButton)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: playPauseButton.topAnchor, constant: -16),
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            playPauseButton.widthAnchor.constraint(equalToConstant: 56),
            playPauseButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        // Keep the scoring row hidden together with the lyric view on an audio-only fallback.
        scoreRow = scores
    }

    private weak var scoreRow: UIStackView?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isMovingFromParent || isBeingDismissed else { return }
        progressProvider.stop()
        progressStarted = false
        karaokeView.reset()
        manager.stopSong()
    }

    @objc private func togglePlayback() { manager.togglePlayback() }
}

extension TmeSingingVC: TmeManagerDelegate {
    func tmeManager(_ manager: TmeManager, didLoad songs: [TmeSong]) {}

    func tmeManager(_ manager: TmeManager, didUpdate status: String) {
        playbackLabel.text = status
        if status == "播放结束" {
            progressProvider.stop()
            progressStarted = false
            playPauseButton.isEnabled = false
        }
    }

    func tmeManager(_ manager: TmeManager, didFail message: String) {
        playbackLabel.text = message
        playPauseButton.isEnabled = false
        progressProvider.stop()
        progressStarted = false
    }

    func tmeManager(_ manager: TmeManager, didChangePlayback isPlaying: Bool) {
        playing = isPlaying
        playPauseButton.isEnabled = manager.canTogglePlayback
        playPauseButton.setImage(UIImage(systemName: isPlaying ? "pause.fill" : "play.fill"),
                                 for: .normal)
        playPauseButton.accessibilityLabel = isPlaying ? "暂停播放" : "继续播放"
        guard hasModel else { return }
        if isPlaying {
            if progressStarted { progressProvider.resume() }
            else { progressProvider.start(); progressStarted = true }
        } else {
            progressProvider.pause()
        }
    }

    func tmeManager(_ manager: TmeManager,
                    didUpdateResource status: TMEScoringPreparation<LyricModel>.Status) {
        switch status {
        case .requestingSongInfo: playbackLabel.text = "正在获取计分资料"
        case .downloadingLyrics: lyricStatusLabel.text = "下载歌词中"
        case .lyricsDownloaded: lyricStatusLabel.text = "下载歌词完成"
        case .downloadingPitch: pitchStatusLabel.text = "下载 pitch 中"
        case .pitchDownloaded: pitchStatusLabel.text = "pitch 下载完成"
        case .parsing: playbackLabel.text = "正在解析计分资料"
        }
    }

    func tmeManager(_ manager: TmeManager, didPrepare model: LyricModel?) {
        guard let model = model else {
            hasModel = false
            progressProvider.stop()
            progressStarted = false
            karaokeView.reset()
            karaokeView.isHidden = true
            scoreRow?.isHidden = true
            fallbackLabel.isHidden = false
            return
        }
        hasModel = true
        fallbackLabel.isHidden = true
        karaokeView.isHidden = false
        scoreRow?.isHidden = false
        karaokeView.setLyricData(data: model, usingInternalScoring: true)
        if playing {
            progressProvider.start()
            progressStarted = true
        }
    }

    func tmeManager(_ manager: TmeManager,
                    didFailPreparation error: TMEScoringPreparation<LyricModel>.PreparationError) {
        switch error {
        case .requestFailed:
            fallbackLabel.text = "歌曲资料请求失败，继续播放"
        case .invalidSongInfo:
            fallbackLabel.text = "歌曲缺少有效歌词或音高资料，继续播放"
        case .invalidURL:
            fallbackLabel.text = "计分资料地址无效，继续播放"
        case .downloadFailed:
            fallbackLabel.text = "计分资料下载失败，继续播放"
        case .invalidFiles:
            fallbackLabel.text = "计分资料解析失败，继续播放"
        }
        if lyricStatusLabel.text != "下载歌词完成" {
            lyricStatusLabel.text = error == .downloadFailed ? "歌词下载中断" : "歌词未就绪"
        }
        if pitchStatusLabel.text != "pitch 下载完成" {
            pitchStatusLabel.text = error == .downloadFailed ? "pitch 下载中断" : "pitch 未就绪"
        }
    }

    func tmeManager(_ manager: TmeManager, didReceivePitch pitch: Double) {
        guard hasModel, playing else { return }
        karaokeView.setPitch(speakerPitch: pitch, progressInMs: 0)
    }
}

extension TmeSingingVC: ProgressProviderDelegate {
    func progressProviderGetPlayerPosition(_ provider: ProgressProvider) -> UInt? {
        manager.playerPosition()
    }

    func progressProvider(_ provider: ProgressProvider, shouldSend postion: UInt) {}

    func progressProvider(_ provider: ProgressProvider, didUpdate progressInMs: UInt) {
        guard hasModel, playing else { return }
        karaokeView.setProgress(progress: progressInMs > 250 ? progressInMs - 250 : progressInMs)
    }
}

extension TmeSingingVC: KaraokeDelegate {
    func onKaraokeView(view: KaraokeView, didFinishLineWith model: LyricLineModel,
                       score: Int, cumulativeScore: Int, lineIndex: Int, lineCount: Int) {
        lineScoreLabel.text = "本句  \(score)"
        totalScoreLabel.text = "累计  \(cumulativeScore) / \(lineCount * 100)"
    }
}
