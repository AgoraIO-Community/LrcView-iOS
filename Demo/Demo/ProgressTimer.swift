//
//  ProgressTimer.swift
//  Demo
//
//  Created by ZYP on 2023/7/3.
//

import Foundation


protocol ProgressTimerDelegate: NSObjectProtocol {
    func progressTimerGetPlayerPosition() -> Int
    func progressTimerDidUpdateProgress(progress: Int)
}

class ProgressTimer: NSObject {
    private var timer = GCDTimer()
    var isPause = false
    var dragging = false
    weak var delegate: ProgressTimerDelegate?
    private var lastCallbackTsOfPlayerPostion: Double = 0.0
    var playerPostion = 0
    
    func start() {
        isPause = false
        lastCallbackTsOfPlayerPostion = CFAbsoluteTimeGetCurrent() * 1000
        timer.scheduledMillisecondsTimer(withName: "ProgressTimer",
                                         countDown: 1000000,
                                         milliseconds: 20,
                                         queue: .main) { [weak self](_, time) in
            guard let self = self else { return }
            if self.isPause {
                return
            }
            
            if self.dragging {
                return
            }
            
            let currentTs = CFAbsoluteTimeGetCurrent() * 1000
            let offset = Int(currentTs - lastCallbackTsOfPlayerPostion)
            if offset < 0 {
                fatalError()
            }
            var progress = playerPostion + offset
            if progress > 250 { /** 进度提前250ms, 第一个句子的第一个字得到更好匹配 **/
                progress -= 250
            }
            delegate?.progressTimerDidUpdateProgress(progress: progress)
        }
    }
    
    func reset() {
        playerPostion = 0
        dragging = false
        timer.destoryAllTimer()
    }
    
    /// use while after drag
    func updateOnDrag(position: Int) {
        dragging = true
//        print("=== updateOnDrag: \(position)")
//        playerPostion = position + 250
//        lastCallbackTsOfPlayerPostion = CFAbsoluteTimeGetCurrent() * 1000
    }
    
    func setPlayerPosition(position: Int) {
        print("=== setPlayerPosition: \(position)")
        if dragging {
            playerPostion = position + 250
            lastCallbackTsOfPlayerPostion = CFAbsoluteTimeGetCurrent() * 1000
            dragging = false
        }
        else {
            if position > playerPostion {
                playerPostion = position
                lastCallbackTsOfPlayerPostion = CFAbsoluteTimeGetCurrent() * 1000
            }
        }
        
    }
}
