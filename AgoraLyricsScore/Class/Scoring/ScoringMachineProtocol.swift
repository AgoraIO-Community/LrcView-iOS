//
//  ScoringMachineProtocol.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2024/6/4.
//

import Foundation

protocol ScoringMachineProtocol {
    typealias Info = ScoringMachineInfo
    typealias DrawInfo = ScoringMachineDrawInfo
    typealias DebugInfo = ScoringMachineDebugInfo
    
    var delegate: ScoringMachineDelegate? { get set }
    /// 游标的起始位置
    var defaultPitchCursorX: CGFloat { get set }
    /// 音准线的高度
    var standardPitchStickViewHeight: CGFloat { get set }
    /// 音准线的基准因子
    var movingSpeedFactor: CGFloat { get set }
    /// 打分容忍度 范围：0-1
    var hitScoreThreshold: Float { get set }
    var scoreLevel: Int { get set }
    var scoreCompensationOffset: Int { get set }
    
    func setLyricData(data: LyricModel?)
    func setProgress(progress: UInt)
    func setPitch(speakerPitch: Double,
                  progressInMs: UInt,
                  score: UInt)
    func dragBegain()
    func dragDidEnd(position: UInt)
    func getCumulativeScore() -> Int
    func reset()
    
    var scoreAlgorithm: IScoreAlgorithm { get set }
    
}

protocol ScoringMachineDelegate: NSObjectProtocol {
    /// 获取渲染视图的尺寸
    func sizeOfCanvasView(_ scoringMachine: ScoringMachineProtocol) -> CGSize
    
    /// 更新渲染信息
    func scoringMachine(_ scoringMachine: ScoringMachineProtocol,
                        didUpdateDraw standardInfos: [ScoringMachineDrawInfo],
                        highlightInfos: [ScoringMachineDrawInfo])
    /// 更新游标位置
    func scoringMachine(_ scoringMachine: ScoringMachineProtocol,
                        didUpdateCursor centerY: CGFloat,
                        showAnimation: Bool,
                        debugInfo: ScoringMachineDebugInfo)
    
    /// 更新句子分数
    func scoringMachine(_ scoringMachine: ScoringMachineProtocol,
                        didFinishLineWith model: LyricLineModel,
                        score: Int,
                        cumulativeScore: Int,
                        lineIndex: Int,
                        lineCount: Int)
}
