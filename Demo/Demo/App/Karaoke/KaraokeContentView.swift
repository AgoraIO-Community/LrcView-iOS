import AgoraLyricsScore
import UIKit

final class KaraokeContentView: UIView {
    let karaokeView = KaraokeView(frame: .zero)
    let lineScoreLabel = UILabel()
    let totalScoreLabel = UILabel()
    let skipPreludeButton = KaraokeContentView.makeControlButton(title: "跳过前奏", symbol: "forward.end")
    let pauseButton = KaraokeContentView.makeControlButton(title: "暂停", symbol: "pause.fill")
    let nextButton = KaraokeContentView.makeControlButton(title: "下一首", symbol: "forward.fill")
    let loadingIndicator = UIActivityIndicatorView(style: .large)
    let messageLabel = UILabel()
    let retryButton = KaraokeContentView.makeOverlayButton(title: "重试")
    let backButton = KaraokeContentView.makeOverlayButton(title: "返回歌曲")
    let openSettingsButton = KaraokeContentView.makeOverlayButton(title: "打开设置")

    private let overlayView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureLayout()
        hideOverlay()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoading(message: String) {
        overlayView.isHidden = false
        messageLabel.text = message
        loadingIndicator.startAnimating()
        retryButton.isHidden = true
        backButton.isHidden = true
        openSettingsButton.isHidden = true
    }

    func showError(message: String, recovery: KaraokeRecovery) {
        overlayView.isHidden = false
        messageLabel.text = message
        loadingIndicator.stopAnimating()
        retryButton.isHidden = recovery != .retry
        backButton.isHidden = false
        openSettingsButton.isHidden = recovery != .systemSettings
    }

    func hideOverlay() {
        overlayView.isHidden = true
        loadingIndicator.stopAnimating()
    }

    func setPaused(_ isPaused: Bool) {
        let title = isPaused ? "继续" : "暂停"
        let symbol = isPaused ? "play.fill" : "pause.fill"
        pauseButton.setTitle(title, for: .normal)
        pauseButton.setImage(UIImage(systemName: symbol), for: .normal)
    }

    private func configureViews() {
        backgroundColor = .black
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
        karaokeView.scoringView.viewHeight = 100
        karaokeView.scoringView.topSpaces = 64
        karaokeView.lyricsView.draggable = false
        karaokeView.lyricsView.showDebugView = false
        karaokeView.backgroundColor = .black

        lineScoreLabel.text = "本句 --"
        totalScoreLabel.text = "总分 0"
        [lineScoreLabel, totalScoreLabel].forEach {
            $0.textColor = .white
            $0.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
            $0.textAlignment = .center
            $0.adjustsFontForContentSizeCategory = true
        }

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.88)
        messageLabel.textColor = .white
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        loadingIndicator.color = .white
        retryButton.accessibilityIdentifier = "karaoke-retry"
        backButton.accessibilityIdentifier = "karaoke-back"
        openSettingsButton.accessibilityIdentifier = "karaoke-open-settings"
    }

    private func configureLayout() {
        let scoreStack = UIStackView(arrangedSubviews: [lineScoreLabel, totalScoreLabel])
        scoreStack.axis = .horizontal
        scoreStack.distribution = .fillEqually
        scoreStack.backgroundColor = UIColor(white: 0.10, alpha: 1)

        let controlStack = UIStackView(arrangedSubviews: [skipPreludeButton, pauseButton, nextButton])
        controlStack.axis = .horizontal
        controlStack.alignment = .fill
        controlStack.distribution = .fillEqually
        controlStack.spacing = 8

        let overlayActions = UIStackView(arrangedSubviews: [retryButton, openSettingsButton, backButton])
        overlayActions.axis = .vertical
        overlayActions.spacing = 10
        overlayActions.alignment = .fill

        let overlayContent = UIStackView(arrangedSubviews: [loadingIndicator, messageLabel, overlayActions])
        overlayContent.axis = .vertical
        overlayContent.spacing = 18
        overlayContent.alignment = .fill

        [karaokeView, scoreStack, controlStack, overlayView, overlayContent].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(karaokeView)
        addSubview(scoreStack)
        addSubview(controlStack)
        addSubview(overlayView)
        overlayView.addSubview(overlayContent)

        NSLayoutConstraint.activate([
            karaokeView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            karaokeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            karaokeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            karaokeView.bottomAnchor.constraint(equalTo: scoreStack.topAnchor, constant: -8),

            scoreStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scoreStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scoreStack.bottomAnchor.constraint(equalTo: controlStack.topAnchor, constant: -8),
            scoreStack.heightAnchor.constraint(equalToConstant: 40),

            controlStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            controlStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            controlStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            controlStack.heightAnchor.constraint(equalToConstant: 48),

            overlayView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

            overlayContent.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            overlayContent.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 32),
            overlayContent.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -32),

            retryButton.heightAnchor.constraint(equalToConstant: 48),
            backButton.heightAnchor.constraint(equalToConstant: 48),
            openSettingsButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private static func makeControlButton(title: String, symbol: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.backgroundColor = UIColor(white: 0.14, alpha: 1)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        return button
    }

    private static func makeOverlayButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.backgroundColor = UIColor(white: 0.16, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        return button
    }
}
