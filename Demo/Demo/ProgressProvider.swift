//
//  ProgressProvider.swift
//  Demo
//
//  Created by ZYP on 2024/4/18.
//

import Foundation

protocol ProgressProviderDelegate: NSObjectProtocol {
    func progressProviderGetPlayerPosition(_ provider: ProgressProvider) -> UInt?
    func progressProvider(_ provider: ProgressProvider, shouldSend postion: UInt)
    func progressProvider(_ provider: ProgressProvider, didUpdate progressInMs: UInt)
}

class ProgressProvider: NSObject {
    weak var delegate: ProgressProviderDelegate?
    private var timer = GCDTimer()
    private var isPause = false
    private var lastPrpgress: UInt = 0
    
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
                current = delegate!.progressProviderGetPlayerPosition(self) ?? current
                delegate?.progressProvider(self, shouldSend: current + 20)
            }
            current += 20

            self.lastPrpgress = current
            delegate?.progressProvider(self, didUpdate: current)
        }
    }
    
    func skip(progress: UInt) {
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
