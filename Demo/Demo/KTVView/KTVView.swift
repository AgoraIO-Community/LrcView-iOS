//
//  KTVView.swift
//  Demo
//
//  Created by ZYP on 2023/3/21.
//

import UIKit
import AgoraLyricsScore
import ScoreEffectUI

/// 包装 KaraokeView & LineScoreView & GradeView & incentiveView
class KTVView: UIView {
    let karaokeView = KaraokeView(frame: .zero, loggers: [ConsoleLogger(), FileLogger()])
    let lineScoreView = LineScoreView()
    let gradeView = GradeView()
    let incentiveView = IncentiveView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
        karaokeView.scoringView.viewHeight = 100
        karaokeView.scoringView.topMargin = 80
        karaokeView.lyricsView.showDebugView = false
        
        backgroundColor = .black
        addSubview(karaokeView)
        addSubview(gradeView)
        addSubview(incentiveView)
        addSubview(lineScoreView)
        
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        gradeView.translatesAutoresizingMaskIntoConstraints = false
        incentiveView.translatesAutoresizingMaskIntoConstraints = false
        lineScoreView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        karaokeView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        gradeView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: 15).isActive = true
        gradeView.leftAnchor.constraint(equalTo: karaokeView.leftAnchor, constant: 15).isActive = true
        gradeView.rightAnchor.constraint(equalTo: karaokeView.rightAnchor, constant: -15).isActive = true
        gradeView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        incentiveView.centerYAnchor.constraint(equalTo: karaokeView.scoringView.centerYAnchor).isActive = true
        incentiveView.centerXAnchor.constraint(equalTo: karaokeView.centerXAnchor, constant: -10).isActive = true
        
        lineScoreView.leftAnchor.constraint(equalTo: leftAnchor, constant: karaokeView.scoringView.defaultPitchCursorX).isActive = true
        lineScoreView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: karaokeView.scoringView.topMargin).isActive = true
        lineScoreView.heightAnchor.constraint(equalToConstant: karaokeView.scoringView.viewHeight).isActive = true
        lineScoreView.widthAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func updateView(param: Param) {
        karaokeView.backgroundImage = param.karaoke.backgroundImage
        karaokeView.scoringEnabled = param.karaoke.scoringEnabled
        karaokeView.spacing = param.karaoke.spacing
        karaokeView.setScoreLevel(level: param.karaoke.scoreLevel)
        karaokeView.setScoreCompensationOffset(offset: param.karaoke.scoreCompensationOffset)
        
        karaokeView.lyricsView.lyricLineSpacing = param.lyric.lyricLineSpacing
        karaokeView.lyricsView.noLyricsTipColor = param.lyric.noLyricTipsColor
        karaokeView.lyricsView.noLyricsTipText = param.lyric.noLyricTipsText
        karaokeView.lyricsView.noLyricsTipFont = param.lyric.noLyricTipsFont
        karaokeView.lyricsView.activeLineUpcomingFontSize = param.lyric.activeLineUpcomingFontSize
        karaokeView.lyricsView.inactiveLineTextColor = param.lyric.inactiveLineTextColor
        karaokeView.lyricsView.activeLineUpcomingTextColor = param.lyric.activeLineUpcomingTextColor
        karaokeView.lyricsView.activeLinePlayedTextColor = param.lyric.activeLinePlayedTextColor
        karaokeView.lyricsView.waitingViewHidden = param.lyric.waitingViewHidden
        karaokeView.lyricsView.inactiveLineFontSize = param.lyric.inactiveLineFontSize
        karaokeView.lyricsView.firstToneHintViewStyle.backgroundColor = param.lyric.firstToneHintViewStyle.backgroundColor
        karaokeView.lyricsView.firstToneHintViewStyle.size = param.lyric.firstToneHintViewStyle.size
        karaokeView.lyricsView.contentTopMargin = param.lyric.contentTopMargin
        karaokeView.lyricsView.firstToneHintViewStyle.topMargin = param.lyric.firstToneHintViewStyle.topMargin
        karaokeView.lyricsView.maxWidth = param.lyric.maxWidth
        karaokeView.lyricsView.draggable = param.lyric.draggable
        karaokeView.lyricsView.showDebugView = param.lyric.showDebugView
        
        karaokeView.scoringView.particleEffectHidden = param.scoring.particleEffectHidden
        karaokeView.scoringView.emitterImages = param.scoring.emitterImages
        karaokeView.scoringView.standardPitchStickViewHighlightColor = param.scoring.standardPitchStickViewHighlightColor
        karaokeView.scoringView.standardPitchStickViewColor = param.scoring.standardPitchStickViewColor
        karaokeView.scoringView.standardPitchStickViewHeight = param.scoring.standardPitchStickViewHeight
        karaokeView.scoringView.defaultPitchCursorX = param.scoring.defaultPitchCursorX
        karaokeView.scoringView.topMargin = param.scoring.topSpaces
        karaokeView.scoringView.viewHeight = param.scoring.viewHeight
        karaokeView.scoringView.hitScoreThreshold = param.scoring.hitScoreThreshold
        karaokeView.scoringView.movingSpeedFactor = param.scoring.movingSpeedFactor
        karaokeView.scoringView.isLocalPitchCursorAlignedWithStandardPitchStick = param.scoring.isLocalPitchCursorAlignedWithStandardPitchStick
        karaokeView.scoringView.showDebugView = param.scoring.showDebugView
        karaokeView.scoringView.localPitchCursorOffsetX = param.scoring.localPitchCursorOffsetX
        karaokeView.scoringView.localPitchCursorImage = param.scoring.localPitchCursorImage
    }

}
