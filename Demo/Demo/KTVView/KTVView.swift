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

}
