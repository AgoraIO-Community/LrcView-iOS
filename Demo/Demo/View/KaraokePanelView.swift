import UIKit
import AgoraLyricsScore
import ScoreEffectUI

/// The lyric and scoring presentation shared by the built-in and TME demos.
final class KaraokePanelView: UIView {
    static let height: CGFloat = 350

    let karaokeView = KaraokeView(frame: .zero, loggers: [ConsoleLogger(), FileLogger()])
    let lineScoreView = LineScoreView()
    let gradeView = GradeView()
    let incentiveView = IncentiveView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
        karaokeView.scoringView.viewHeight = 100
        karaokeView.scoringView.topSpaces = 80
        karaokeView.lyricsView.showDebugView = false

        [karaokeView, gradeView, incentiveView, lineScoreView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            karaokeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            karaokeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            karaokeView.topAnchor.constraint(equalTo: topAnchor),
            // Keep child layout valid when TME collapses the hidden panel while preparing.
            karaokeView.heightAnchor.constraint(equalToConstant: Self.height),
            gradeView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: 15),
            gradeView.leadingAnchor.constraint(equalTo: karaokeView.leadingAnchor, constant: 15),
            gradeView.trailingAnchor.constraint(equalTo: karaokeView.trailingAnchor, constant: -15),
            gradeView.heightAnchor.constraint(equalToConstant: 40),
            incentiveView.centerYAnchor.constraint(equalTo: karaokeView.scoringView.centerYAnchor),
            incentiveView.centerXAnchor.constraint(equalTo: karaokeView.centerXAnchor, constant: -10),
            lineScoreView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                   constant: karaokeView.scoringView.defaultPitchCursorX),
            lineScoreView.topAnchor.constraint(equalTo: karaokeView.topAnchor,
                                               constant: karaokeView.scoringView.topSpaces),
            lineScoreView.heightAnchor.constraint(equalToConstant: karaokeView.scoringView.viewHeight),
            lineScoreView.widthAnchor.constraint(equalToConstant: 50)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
