//
//  Events.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import Foundation

@objc public protocol KaraokeDelegate {
    /// 拖拽歌词结束后回调
    /// - Note: 当 `KaraokeConfig.lyricConfig.draggable == true` 且 用户进行拖动歌词时候 调用
    /// - Parameters:
    ///   - view: KaraokeView
    ///   - position: 当前时间点 (ms)
    @objc optional func onKaraokeView(view: KaraokeView, didDragTo position: Int)
     
    /// 歌曲播放完一行(Line)时的歌词回调
    /// - Parameters:
    ///   - model: 行信息
    ///   - score: 当前行得分 [0, 100]
    ///   - lineIndex: 行索引号 最小值：0
    ///   - lineCount: 总行数
    @objc optional func onKaraokeView(view: KaraokeView,
                                      didFinishLineWith model: LyricLineModel,
                                      score: Int,
                                      lineIndex: Int,
                                      lineCount: Int)
}

/// 分数计算协议
@objc public protocol IScoreAlgorithm {
    /// 计算当前行(Line)的分数
    /// - Parameters:
    ///   - models: 字得分信息集合
    /// - Returns: 计算后的分数 [0, 100]
    @objc func getLineScore(with toneScores: [ToneScoreModel]) -> Int
    
    @objc func incentiveGradeCount() -> Int
    @objc func incentiveGradeIndex(score: Int) -> Int
    @objc func incentiveGradeDescription(gradeIndex: Int) -> String
    @objc func incentiveCombinable(gradeIndex: Int) -> Bool
    
    @objc func totalGradeCount() -> Int
    @objc func totalGradeIndex(score: Int) -> Int
    @objc func totalGradeDescription(gradeIndex: Int) -> Int
}
