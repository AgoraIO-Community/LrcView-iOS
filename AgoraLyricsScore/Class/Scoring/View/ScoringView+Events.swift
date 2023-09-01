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
                     cumulativeScore: Int,
                     lineIndex: Int,
                     lineCount: Int)
    
    
    /// 更新tone分数
    /// - Parameters:
    ///   - models: 得分详细数据
    ///   - cumulativeScore: 累计分数
    func scoringView(_ view: ScoringView,
                     didFinishToneWith models: [PitchScoreModel],
                     cumulativeScore: Int)
    
    /// 更新UI
    func scoringViewShouldUpdateViewLayout(view: ScoringView)
}
