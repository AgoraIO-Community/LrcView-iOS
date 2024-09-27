//
//  MainTestVCEx+Debug.swift
//  Demo
//
//  Created by ZYP on 2024/5/13.
//

import Foundation

extension MainTestVCEx { /** for debug **/
    static var lastProgressInMs: UInt = 0
    static var lastPitchTime: CFAbsoluteTime = 0
    
    func updateLastProgressInMs_debug(progressInMs: UInt) {
        MainTestVCEx.lastProgressInMs = progressInMs
    }
    
    func calculateProgressGap_debug(progressInMs: UInt) -> Int {
        if progressInMs > 3 * 60 * 60 * 1000 {
            Log.errorText(text: "progressInMs is too max, it not expect for normal song's durations", tag: logTag)
        }
        let progressGap = Int(progressInMs) - Int(MainTestVCEx.lastProgressInMs)
        MainTestVCEx.lastProgressInMs = progressInMs
        return progressGap
    }
    
    /// 打印onPitch回调间隔
    func logOnPitchInvokeGap_debug() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let gap = startTime - MainTestVCEx.lastPitchTime
        MainTestVCEx.lastPitchTime = startTime
        if (gap > 0.1) {
            Log.warning(text: "OnPitch invoke gap \(gap)", tag: self.logTag)
        }
        else {
            Log.debug(text: "OnPitch invoke gap \(gap)", tag: self.logTag)
        }
    }
    
    // 打印非法的speakerPitch
    func logInvalidSpeakPitch_debug(speakerPitch: Int) {
        if (speakerPitch < 0) {
            Log.errorText(text: "speakerPitch less than 0, \(speakerPitch)", tag: self.logTag)
        }
    }
}
