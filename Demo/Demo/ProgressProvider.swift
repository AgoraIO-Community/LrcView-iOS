//
//  ProgressProvider.swift
//  Demo
//
//  Created by ZYP on 2024/4/18.
//

import Foundation

protocol ProgressProviderDelegate: NSObjectProtocol {
    func progressProviderGetPlayerPosition(_ provider: ProgressProvider) -> Int
    func progressProvider(_ provider: ProgressProvider, shouldSend postion: Int)
    func progressProvider(_ provider: ProgressProvider, didUpdate progressInMs: Int)
}

class ProgressProvider: NSObject {
    weak var delegate: ProgressProviderDelegate?
    private var timer = GCDTimer()
    private var isPause = false
    private var lastPrpgress = 0
    
    func startTime() {
        timer.scheduledMillisecondsTimer(withName: "MainTestVC",
                                         countDown: 1000000,
                                         milliseconds: 20,
                                         queue: .main) { [weak self](_, time) in

            guard let self = self else { return }
            if self.isPause {
                return
            }
            
            var current = self.lastPrpgress
            if time.truncatingRemainder(dividingBy: 1000) == 0 {
                current = delegate!.progressProviderGetPlayerPosition(self)
                delegate?.progressProvider(self, shouldSend: current + 20)
            }
            current += 20

            self.lastPrpgress = current
            var time = current
//            if time > 250 { /** 进度提前250ms, 第一个句子的第一个字得到更好匹配 **/
//                time -= 250
//            }
            delegate?.progressProvider(self, didUpdate: time)
        }
    }
    
    func skip(progress: Int) {
        timer.destoryTimer(withName: "MainTestVC")
        lastPrpgress = progress
        startTime()
    }
    
    func pause() {
        isPause = true
    }
    
    func resume() {
        isPause = false
    }
    
    func stop() {
        isPause = true
        timer.destoryTimer(withName: "MainTestVC")
    }
}
