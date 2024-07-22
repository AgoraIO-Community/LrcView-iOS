//
//  MiniSizeVC.swift
//  Demo
//
//  Created by ZYP on 2023/1/30.
//

import UIKit
import AgoraRtcKit
import RTMTokenBuilder
import AgoraLyricsScore
import ScoreEffectUI
import SVProgressHUD

class MiniSizeVC: MainTestVC {
    
    override func viewDidLoad() {
        logTag = "MiniSizeVC"
        super.viewDidLoad()
        mainView.gradeView.isHidden = true
        mainView.karaokeViewHeightConstraint.constant = 80
        let space = (view.bounds.size.width - 150)/2
        mainView.karaokeViewLeftConstraint.constant = space
        mainView.karaokeViewRightConstraint.constant = -1 * space
        
        mainView.karaokeView.scoringView.viewHeight = 100
        mainView.karaokeView.scoringView.topSpaces = 0
        mainView.karaokeView.lyricsView.showDebugView = false
        mainView.karaokeView.lyricsView.draggable = true
        mainView.karaokeView.scoringEnabled = false
        mainView.karaokeView.lyricsView.inactiveLineFontSize = UIFont(name: "PingFangSC-Semibold", size: 13)!
        mainView.karaokeView.lyricsView.activeLinePlayedTextColor = .colorWithHex(hexStr: "#FF8AE4")
        mainView.karaokeView.lyricsView.inactiveLineTextColor = UIColor.white.withAlphaComponent(0.6)
        mainView.karaokeView.lyricsView.waitingViewHidden = true
        mainView.karaokeView.lyricsView.lyricLineSpacing = 1
        mainView.karaokeView.lyricsView.activeLinePosition = .top
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
}

