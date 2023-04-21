//
//  LyricMachine+Events.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/3/13.
//

import Foundation

protocol LyricMachineDelegate: NSObjectProtocol {
    /// 在 `setLyricData` 完成后调用
    func lyricMachine(_ lyricMachine: LyricMachine,
                      didSetLyricData datas: [LyricCell.Model])
    
    /// 在 `setLyricData` 完成后调用
    /// - Parameters:
    ///   - remainingTime: 倒计时剩余时间
    func lyricMachine(_ lyricMachine: LyricMachine, didUpdate remainingTime: Int)
    
    /// 换行时调用
    func lyricMachine(_ lyricMachine: LyricMachine,
                      didStartLineAt newIndexPath: IndexPath,
                      oldIndexPath: IndexPath,
                      animated: Bool)
    /// 行更新时调用
    func lyricMachine(_ lyricMachine: LyricMachine, didUpdateLineAt indexPath: IndexPath)
    
    /// Consloe信息 (仅用于debug)
    func lyricMachine(_ lyricMachine: LyricMachine, didUpdateConsloe text: String)
}

extension LyricMachine { /** invoke **/
    func invokeLyricMachine(didSetLyricData datas: [LyricCell.Model]) {
        if Thread.isMainThread {
            delegate?.lyricMachine(self, didSetLyricData: datas)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.lyricMachine(self, didSetLyricData: datas)
        }
    }
    
    func invokeLyricMachine(didUpdate remainingTime: Int) {
        if Thread.isMainThread {
            delegate?.lyricMachine(self, didUpdate: remainingTime)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.lyricMachine(self, didUpdate: remainingTime)
        }
    }
    
    func invokeLyricMachine(didStartLineAt newIndexPath: IndexPath,
                            oldIndexPath: IndexPath, animated: Bool) {
        if Thread.isMainThread {
            delegate?.lyricMachine(self,
                                   didStartLineAt: newIndexPath,
                                   oldIndexPath: oldIndexPath,
                                   animated: animated)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.lyricMachine(self,
                                        didStartLineAt: newIndexPath,
                                        oldIndexPath: oldIndexPath,
                                        animated: animated)
        }
    }
    
    func invokeLyricMachine(didUpdateLineAt indexPath: IndexPath) {
        if Thread.isMainThread {
            delegate?.lyricMachine(self, didUpdateLineAt: indexPath)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.lyricMachine(self, didUpdateLineAt: indexPath)
        }
    }
    
    func invokeLyricMachine(didUpdateConsloe text: String) {
        if Thread.isMainThread {
            delegate?.lyricMachine(self, didUpdateConsloe: text)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.lyricMachine(self, didUpdateConsloe: text)
        }
    }
}
