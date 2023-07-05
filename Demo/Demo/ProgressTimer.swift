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
    private var last = 0
    weak var delegate: ProgressTimerDelegate?
     
    func start() {
        isPause = false
        last = 0
        timer.scheduledMillisecondsTimer(withName: "ProgressTimer",
                                         countDown: 1000000,
                                         milliseconds: 20,
                                         queue: .main) { [weak self](_, time) in
            guard let self = self else { return }
            if self.isPause {
                return
            }
            
            var current = self.last
            if time.truncatingRemainder(dividingBy: 1000) == 0 {
                current = delegate!.progressTimerGetPlayerPosition()
            }
            current += 20
            
            self.last = current
            var progress = current
            if progress > 250 { /** 进度提前250ms, 第一个句子的第一个字得到更好匹配 **/
                progress -= 250
            }
            delegate?.progressTimerDidUpdateProgress(progress: progress)
        }
    }
    
    func reset() {
        timer.destoryAllTimer()
    }
    
    func updateLastTime(time: Int) {
        last = time
    }
}
