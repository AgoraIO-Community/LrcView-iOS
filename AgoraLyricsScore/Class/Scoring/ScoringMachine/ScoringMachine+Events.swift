//
//  ScoringMachine+Events.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

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
}
