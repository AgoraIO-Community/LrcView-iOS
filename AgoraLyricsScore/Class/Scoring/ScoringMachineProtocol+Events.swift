//
//  ScoringMachineProtocol+Events.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2024/6/4.
//

import Foundation

struct ScoringMachineEventInvoker {
    static func invokeScoringMachine(scoringMachine: ScoringMachineProtocol,
                                     didUpdateDraw standardInfos: [ScoringMachineDrawInfo],
                                     highlightInfos: [ScoringMachineDrawInfo]) {
        if Thread.isMainThread {
            scoringMachine.delegate?.scoringMachine(scoringMachine,
                                                    didUpdateDraw: standardInfos,
                                                    highlightInfos: highlightInfos)
            return
        }
        
        DispatchQueue.main.async {
            scoringMachine.delegate?.scoringMachine(scoringMachine,
                                                    didUpdateDraw: standardInfos,
                                                    highlightInfos: highlightInfos)
        }
    }
    
    static func invokeScoringMachine(scoringMachine: ScoringMachineProtocol, didUpdateCursor centerY: CGFloat,
                                     showAnimation: Bool,
                                     debugInfo: ScoringMachineDebugInfo) {
        if Thread.isMainThread {
            scoringMachine.delegate?.scoringMachine(scoringMachine,
                                                    didUpdateCursor: centerY,
                                                    showAnimation: showAnimation,
                                                    debugInfo: debugInfo)
            return
        }
        
        DispatchQueue.main.async {
            scoringMachine.delegate?.scoringMachine(scoringMachine,
                                                    didUpdateCursor: centerY,
                                                    showAnimation: showAnimation,
                                                    debugInfo: debugInfo)
        }
    }
    
    static func invokeScoringMachine(scoringMachine: ScoringMachineProtocol,
                                     didFinishLineWith model: LyricLineModel,
                                     score: Int,
                                     cumulativeScore: Int,
                                     lineIndex: Int,
                                     lineCount: Int) {
        if Thread.isMainThread {
            scoringMachine.delegate?.scoringMachine(scoringMachine,
                                                    didFinishLineWith: model,
                                                    score: score,
                                                    cumulativeScore: cumulativeScore,
                                                    lineIndex: lineIndex,
                                                    lineCount: lineCount)
            return
        }
        
        DispatchQueue.main.async {
            scoringMachine.delegate?.scoringMachine(scoringMachine,
                                                    didFinishLineWith: model,
                                                    score: score,
                                                    cumulativeScore: cumulativeScore,
                                                    lineIndex: lineIndex,
                                                    lineCount: lineCount)
        }
    }
}
