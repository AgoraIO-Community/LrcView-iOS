//
//  ScoringView+Events.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/13.
//

import Foundation

protocol ScoringViewDelegate: NSObjectProtocol {
    /// 更新句子分数
    func scoringVM(_ vm: ScoringView,
                   didFinishLineWith model: LyricLineModel,
                   score: Int,
                   lineIndex: Int,
                   lineCount: Int)
}
