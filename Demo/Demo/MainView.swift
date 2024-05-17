//
//  MainView.swift
//  Demo
//
//  Created by ZYP on 2024/4/23.
//

import UIKit
import AgoraLyricsScoreEx
import ScoreEffectUI
import AgoraLyricsScore

extension MainView {
    enum Action {
        case skip
        case pause
        case set
        case change
        case quick
    }
}

protocol MainViewDelegate: NSObjectProtocol {
    func mainView(_ mainView: MainView, onAction: MainView.Action)
}

class MainView: UIView {
    weak var delegate: MainViewDelegate?
    let karaokeView = KaraokeViewEx(frame: .zero, loggers: [ConsoleLoggerEx(), FileLoggerEx()])
    let karaokeView1 = KaraokeView(frame: .zero, loggers: [ConsoleLogger(), FileLogger()])
    let lineScoreView = LineScoreView()
    let gradeView = GradeView()
    let incentiveView = IncentiveView()
    private let skipButton = UIButton()
    private let setButton = UIButton()
    private let quickButton = UIButton()
    private let changeButton = UIButton()
    private let pauseButton = UIButton()
    private let label = UILabel()
    private let consoleView = ConsoleView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
        karaokeView.scoringView.viewHeight = 100
        karaokeView.scoringView.topSpaces = 80
        karaokeView.lyricsView.showDebugView = false
        karaokeView.lyricsView.draggable = true
        
        skipButton.setTitle("跳过前奏", for: .normal)
        setButton.setTitle("设置参数", for: .normal)
        changeButton.setTitle("切歌", for: .normal)
        quickButton.setTitle("退出", for: .normal)
        pauseButton.setTitle("暂停", for: .normal)
        pauseButton.setTitle("继续", for: .selected)
        skipButton.backgroundColor = .red
        setButton.backgroundColor = .red
        changeButton.backgroundColor = .red
        quickButton.backgroundColor = .red
        pauseButton.backgroundColor = .red
        label.textColor = .white
        label.backgroundColor = .red
        
        backgroundColor = .black
        addSubview(karaokeView)
        addSubview(gradeView)
        addSubview(incentiveView)
        addSubview(skipButton)
        addSubview(setButton)
        addSubview(changeButton)
        addSubview(quickButton)
        addSubview(pauseButton)
        addSubview(lineScoreView)
        addSubview(label)
        addSubview(consoleView)
        
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        gradeView.translatesAutoresizingMaskIntoConstraints = false
        incentiveView.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        setButton.translatesAutoresizingMaskIntoConstraints = false
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        quickButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        lineScoreView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        consoleView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
        
        gradeView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: 15).isActive = true
        gradeView.leftAnchor.constraint(equalTo: karaokeView.leftAnchor, constant: 15).isActive = true
        gradeView.rightAnchor.constraint(equalTo: karaokeView.rightAnchor, constant: -15).isActive = true
        gradeView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        incentiveView.centerYAnchor.constraint(equalTo: karaokeView.scoringView.centerYAnchor).isActive = true
        incentiveView.centerXAnchor.constraint(equalTo: karaokeView.centerXAnchor, constant: -10).isActive = true
        
        lineScoreView.leftAnchor.constraint(equalTo: leftAnchor, constant: karaokeView.scoringView.defaultPitchCursorX).isActive = true
        lineScoreView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: karaokeView.scoringView.topSpaces).isActive = true
        lineScoreView.heightAnchor.constraint(equalToConstant: karaokeView.scoringView.viewHeight).isActive = true
        lineScoreView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        skipButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 100).isActive = true
        skipButton.topAnchor.constraint(equalTo: karaokeView.bottomAnchor, constant: 30).isActive = true
        
        setButton.leftAnchor.constraint(equalTo: skipButton.rightAnchor, constant: 45).isActive = true
        setButton.topAnchor.constraint(equalTo: karaokeView.bottomAnchor, constant: 30).isActive = true
        
        changeButton.leftAnchor.constraint(equalTo: skipButton.leftAnchor).isActive = true
        changeButton.topAnchor.constraint(equalTo: setButton.bottomAnchor, constant: 30).isActive = true
        
        quickButton.leftAnchor.constraint(equalTo: setButton.leftAnchor).isActive = true
        quickButton.topAnchor.constraint(equalTo: setButton.bottomAnchor, constant: 30).isActive = true
        
        pauseButton.leftAnchor.constraint(equalTo: skipButton.leftAnchor).isActive = true
        pauseButton.topAnchor.constraint(equalTo: changeButton.bottomAnchor, constant: 30).isActive = true
        
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        consoleView.rightAnchor.constraint(equalTo: karaokeView.rightAnchor).isActive = true
        consoleView.bottomAnchor.constraint(equalTo: karaokeView.bottomAnchor).isActive = true
        consoleView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        consoleView.widthAnchor.constraint(equalToConstant: 150).isActive = true
    }
    
    func commonInit() {
        skipButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        setButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        changeButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        quickButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
    }
    
    func updateView(param: Param) {
        karaokeView.backgroundImage = param.karaoke.backgroundImage
        karaokeView.scoringEnabled = param.karaoke.scoringEnabled
        karaokeView.spacing = param.karaoke.spacing
        
        karaokeView.lyricsView.lyricLineSpacing = param.lyric.lyricLineSpacing
        karaokeView.lyricsView.noLyricTipsColor = param.lyric.noLyricTipsColor
        karaokeView.lyricsView.noLyricTipsText = param.lyric.noLyricTipsText
        karaokeView.lyricsView.noLyricTipsFont = param.lyric.noLyricTipsFont
        karaokeView.lyricsView.activeLineUpcomingFontSize = param.lyric.activeLineUpcomingFontSize
        karaokeView.lyricsView.inactiveLineTextColor = param.lyric.inactiveLineTextColor
        karaokeView.lyricsView.activeLineUpcomingTextColor = param.lyric.activeLineUpcomingTextColor
        karaokeView.lyricsView.activeLinePlayedTextColor = param.lyric.activeLinePlayedTextColor
        karaokeView.lyricsView.waitingViewHidden = param.lyric.waitingViewHidden
        karaokeView.lyricsView.inactiveLineFontSize = param.lyric.inactiveLineFontSize
        karaokeView.lyricsView.firstToneHintViewStyle.backgroundColor = param.lyric.firstToneHintViewStyle.backgroundColor
        karaokeView.lyricsView.firstToneHintViewStyle.size = param.lyric.firstToneHintViewStyle.size
        karaokeView.lyricsView.firstToneHintViewStyle.bottomMargin = param.lyric.firstToneHintViewStyle.bottomMargin
        karaokeView.lyricsView.draggable = param.lyric.draggable
        
        karaokeView.scoringView.particleEffectHidden = param.scoring.particleEffectHidden
        karaokeView.scoringView.emitterImages = param.scoring.emitterImages
        karaokeView.scoringView.standardPitchStickViewHighlightColor = param.scoring.standardPitchStickViewHighlightColor
        karaokeView.scoringView.standardPitchStickViewColor = param.scoring.standardPitchStickViewColor
        karaokeView.scoringView.standardPitchStickViewHeight = param.scoring.standardPitchStickViewHeight
        karaokeView.scoringView.defaultPitchCursorX = param.scoring.defaultPitchCursorX
        karaokeView.scoringView.topSpaces = param.scoring.topSpaces
        karaokeView.scoringView.viewHeight = param.scoring.viewHeight
        karaokeView.scoringView.movingSpeedFactor = param.scoring.movingSpeedFactor
        karaokeView.scoringView.showDebugView = param.scoring.showDebugView
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        switch sender {
        case skipButton:
            delegate?.mainView(self, onAction: .skip)
            return
        case setButton:
            delegate?.mainView(self, onAction: .set)
            return
        case changeButton:
            delegate?.mainView(self, onAction: .change)
            return
        case quickButton:
            delegate?.mainView(self, onAction: .quick)
            return
        case pauseButton:
            delegate?.mainView(self, onAction: .pause)
            return
        default:
            break
        }
    }
    
    func setConsoleText(_ text: String) {
        consoleView.set(text: text)
    }
}

class ConsoleView: UIView {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .systemFont(ofSize: 9)
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        label.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(text: String) {
        label.text = text
    }
}
