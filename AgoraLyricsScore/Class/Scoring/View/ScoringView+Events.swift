//
//  ScoringView+Events.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/13.
//

import Foundation

protocol ScoringViewDelegate: NSObjectProtocol {
    /// 更新句子分数
    func scoringView(_ view: ScoringView,
                   didFinishLineWith model: LyricLineModel,
                   score: Int,
                   lineIndex: Int,
                   lineCount: Int)
    
    /// 更新UI
    func scoringViewShouldUpdateViewLayout(view: ScoringView)
}
