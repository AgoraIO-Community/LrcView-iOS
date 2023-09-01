//
//  ScoringMachine+Events.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

protocol ScoringMachineDelegate: NSObjectProtocol {
    /// 获取渲染视图的尺寸
    func sizeOfCanvasView(_ scoringMachine: ScoringMachine) -> CGSize
    
    /// 更新渲染信息
    func scoringMachine(_ scoringMachine: ScoringMachine,
                        didUpdateDraw standardInfos: [ScoringMachine.DrawInfo],
                        highlightInfos: [ScoringMachine.DrawInfo])
    /// 更新游标位置
    func scoringMachine(_ scoringMachine: ScoringMachine,
                        didUpdateCursor centerY: CGFloat,
                        showAnimation: Bool,
                        debugInfo: ScoringMachine.DebugInfo)
    
    /// 更新句子分数
    func scoringMachine(_ scoringMachine: ScoringMachine,
                        didFinishLineWith model: LyricLineModel,
                        score: Int,
                        cumulativeScore: Int,
                        lineIndex: Int,
                        lineCount: Int)
    
    /// 更新句子分数2
    func scoringMachine(_ scoringMachine: ScoringMachine,
                        didFinishToneWith models: [PitchScoreModel],
                        cumulativeScore: Int)
}

extension ScoringMachine { /** invoke **/
    func invokeScoringMachine(didUpdateDraw standardInfos: [ScoringMachine.DrawInfo],
                              highlightInfos: [ScoringMachine.DrawInfo]) {
        if Thread.isMainThread {
            delegate?.scoringMachine(self,
                                     didUpdateDraw: standardInfos,
                                     highlightInfos: highlightInfos)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scoringMachine(self,
                                          didUpdateDraw: standardInfos,
                                          highlightInfos: highlightInfos)
        }
    }
    
    func invokeScoringMachine(didUpdateCursor centerY: CGFloat,
                              showAnimation: Bool,
                              debugInfo: DebugInfo) {
        if Thread.isMainThread {
            delegate?.scoringMachine(self,
                                     didUpdateCursor: centerY,
                                     showAnimation: showAnimation,
                                     debugInfo: debugInfo)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scoringMachine(self,
                                          didUpdateCursor: centerY,
                                          showAnimation: showAnimation,
                                          debugInfo: debugInfo)
        }
    }
    
    func invokeScoringMachine(didFinishLineWith model: LyricLineModel,
                              score: Int,
                              cumulativeScore: Int,
                              lineIndex: Int,
                              lineCount: Int) {
        if Thread.isMainThread {
            delegate?.scoringMachine(self,
                                     didFinishLineWith: model,
                                     score: score,
                                     cumulativeScore: cumulativeScore,
                                     lineIndex: lineIndex,
                                     lineCount: lineCount)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scoringMachine(self,
                                          didFinishLineWith: model,
                                          score: score,
                                          cumulativeScore: cumulativeScore,
                                          lineIndex: lineIndex,
                                          lineCount: lineCount)
        }
    }
    
    func invokeScoringMachine(didFinishToneWith models: [PitchScoreModel], cumulativeScore: Int) {
        if Thread.isMainThread {
            delegate?.scoringMachine(self, didFinishToneWith: models, cumulativeScore: cumulativeScore)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scoringMachine(self, didFinishToneWith: models, cumulativeScore: cumulativeScore)
        }
    }
}
