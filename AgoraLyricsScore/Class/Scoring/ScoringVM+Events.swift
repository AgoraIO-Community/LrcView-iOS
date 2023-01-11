//
//  ScoringVM+Events.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

protocol ScoringVMDelegate: NSObjectProtocol {
    /// 获取渲染视图的尺寸
    func sizeOfCanvasView(_ vm: ScoringVM) -> CGSize
    
    /// 更新渲染信息
    func scoringVM(_ vm: ScoringVM,
                   didUpdateDraw standardInfos: [ScoringVM.DrawInfo],
                   highlightInfos: [ScoringVM.DrawInfo])
    /// 更新游标位置
    func scoringVM(_ vm: ScoringVM,
                   didUpdateCursor centerY: CGFloat,
                   showAnimation: Bool)
}


extension ScoringVM { /** invoke **/
    func invokeScoringVM(didUpdateDraw standardInfos: [ScoringVM.DrawInfo],
                         highlightInfos: [ScoringVM.DrawInfo]) {
        if Thread.isMainThread {
            delegate?.scoringVM(self,
                                didUpdateDraw: standardInfos,
                                highlightInfos: highlightInfos)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scoringVM(self,
                                     didUpdateDraw: standardInfos,
                                     highlightInfos: highlightInfos)
        }
    }
    
    func invokeScoringVM(didUpdateCursor centerY: CGFloat,
                         showAnimation: Bool) {
        if Thread.isMainThread {
            delegate?.scoringVM(self,
                                didUpdateCursor: centerY,
                                showAnimation: showAnimation)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.scoringVM(self,
                                     didUpdateCursor: centerY,
                                     showAnimation: showAnimation)
        }
    }
}
