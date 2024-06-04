//
//  ScoringMachineEx+Events.swift.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2024/6/3.
//

import Foundation

extension ScoringMachineEx { /** invoke **/
    func invokeScoringMachine(didUpdateDraw standardInfos: [ScoringMachineDrawInfo],
                              highlightInfos: [ScoringMachineDrawInfo]) {
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
                              debugInfo: ScoringMachineDebugInfo) {
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
}
