//
//  MainTestController.swift
//  Demo
//
//  Created by ZYP on 2023/1/30.
//

import UIKit
import AgoraRtcKit


class MiniSizeVC: MainTestVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainView.karaokeViewWidthAnchor?.constant = 140
        mainView.karaokeViewHeightAnchor?.constant = 80
        mainView.gradeView.isHidden = true
        mainView.lineScoreView.isHidden = true
        mainView.incentiveView.isHidden = true
        
        let karaokeView = mainView.karaokeView
        karaokeView.scoringView.viewHeight = 100
        karaokeView.scoringView.topSpaces = 0
        karaokeView.lyricsView.showDebugView = false
        karaokeView.lyricsView.draggable = true
        karaokeView.scoringEnabled = false
        karaokeView.lyricsView.inactiveLineFontSize = UIFont(name: "PingFangSC-Semibold", size: 13)!
        karaokeView.lyricsView.activeLinePlayedTextColor = .colorWithHex(hexStr: "#FF8AE4")
        karaokeView.lyricsView.inactiveLineTextColor = UIColor.white.withAlphaComponent(0.6)
        karaokeView.lyricsView.waitingViewHidden = true
        karaokeView.lyricsView.lyricLineSpacing = 1
        karaokeView.lyricsView.activeLinePosition = .top
    }
}
