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
    // MARK: - 自定义分数
    
    /// 计算当前行(Line)的分数
    /// - Parameters:
    ///   - models: 字得分信息集合
    /// - Returns: 计算后的分数 [0, 100]
    @objc func getLineScore(with toneScores: [ToneScoreModel]) -> Int
    
    // MARK: - 自定义激励分布
    
    /// 获取激励的数量
    /// - Returns: 激励的总数量
    @objc func incentiveGradeCount() -> Int
    
    /// 计算当前分数属于哪种激励
    /// - Parameter score: 一句的分数
    /// - Returns: 激励的索引
    @objc func incentiveGradeIndex(score: Int) -> Int
    
    /// 激励的描述
    /// - Note: 在视图中显示的名称
    /// - Parameter gradeIndex: 激励索引
    /// - Returns: 激励名称
    @objc func incentiveGradeDescription(gradeIndex: Int) -> String
    
    /// 激励是否可Combin
    /// - Note: 如果可以，则在重复的时候追加显示 “X2” “X3”
    /// - Parameter gradeIndex: 激励的索引
    /// - Returns: Combinable
    @objc func incentiveCombinable(gradeIndex: Int) -> Bool
    
    // MARK: - 自定义等级分布
    
    /// 获取等级分布的数量
    @objc func totalGradeCount() -> Int
    
    /// 等级对应的总分数百分比
    /// - Parameter index: 当前等级索引
    /// - Returns: 分数 0-100 (把总分当做100分，内部按照百分比计算)
    @objc func totalGradeScoreByIndex(gradeIndex: Int) -> Int
    
    /// 等级的描述
    /// - Note: 在视图中显示的名称
    /// - Parameter gradeIndex: 等级的索引
    /// - Returns: 等级名称
    @objc func totalGradeDescription(gradeIndex: Int) -> String
    
    /// 等级的图片
    /// - Parameter gradeIndex: 等级的索引
    /// - Returns: 等级图片
    @objc func totalGradeImage(gradeIndex: Int) -> UIImage
}

extension IScoreAlgorithm {
    /// 计算分数等级 当一句结束的时候回调
    /// - Parameter score: 每一句的分数
    /// - Parameter gradeScores: 等级参考分数
    /// - Returns: 等级索引, `nil`表示没有匹配上
    func totalGradeIndex(cumulativeScore: Int,
                         totalScore: Int,
                         gradeScores: [Int]) -> Int? {
        guard !gradeScores.isEmpty else {
            return nil
        }
        
        if cumulativeScore < 0 {
            return nil
        }
        
        let ratio = Float(cumulativeScore)/Float(totalScore)
        if ratio > 1 {
            return gradeScores.count - 1
        }
        
        if ratio < Float(gradeScores.first!) / 100 {
            return nil
        }
        
        var last: Int? = nil
        for item in gradeScores.enumerated() {
            if ratio == Float(item.element) / 100 {
                return item.offset
            }
            if ratio >= Float(item.element) / 100 {
                last = item.offset
            }
        }
        return last
    }
}
