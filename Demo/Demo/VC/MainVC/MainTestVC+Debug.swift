//
//  MainTestVC+Debug.swift
//  Demo
//
//  Created by ZYP on 2024/9/24.
//

import Foundation

extension MainTestVC { /** for debug **/
    static var lastProgressInMs: UInt = 0
    static var lastPitchTime: CFAbsoluteTime = 0
    
    func updateLastProgressInMs_debug(progressInMs: UInt) {
        MainTestVC.lastProgressInMs = progressInMs
    }
    
    func calculateProgressGap_debug(progressInMs: UInt) -> Int {
        let progressGap = Int(progressInMs) - Int(MainTestVC.lastProgressInMs)
        MainTestVC.lastProgressInMs = progressInMs
        return progressGap
    }
    
    /// 打印onPitch回调间隔
    func logOnPitchInvokeGap_debug() {
        let startTime = CFAbsoluteTimeGetCurrent()
        let gap = startTime - MainTestVC.lastPitchTime
        MainTestVC.lastPitchTime = startTime
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
