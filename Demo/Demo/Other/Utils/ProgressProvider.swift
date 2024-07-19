//
//  ProgressProvider.swift
//  Demo
//
//  Created by ZYP on 2024/4/18.
//

import Foundation

protocol ProgressProviderDelegate: NSObjectProtocol {
    /// 读取播放器的进度，用于校准。
    func progressProviderGetPlayerPosition(_ provider: ProgressProvider) -> UInt?
    /// 通知外部广播发送进度
    func progressProvider(_ provider: ProgressProvider, shouldSend postion: UInt)
    /// 进度更新
    func progressProvider(_ provider: ProgressProvider, didUpdate progressInMs: UInt)
}

/// 提供20ms级别的歌曲进度
class ProgressProvider: NSObject {
    weak var delegate: ProgressProviderDelegate?
    private var timer = GCDTimer()
    private var isPause = false
    private var lastPrpgress: UInt = 0
    
    func start() {
        timer.scheduledMillisecondsTimer(withName: "ProgressProvider",
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
    
    func seek(position: UInt) {
        timer.destoryTimer(withName: "ProgressProvider")
        lastPrpgress = position
        start()
    }
    
    func pause() {
        isPause = true
    }
    
    func resume() {
        isPause = false
    }
    
    func stop() {
        isPause = false
        lastPrpgress = 0
        timer.destoryTimer(withName: "ProgressProvider")
    }
}
