//
//  ToneCalculator.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

class ToneCalculator {
    /// 计算tone分数
    /// - Parameters:
    ///   - minPitch: 来自歌词文件中最大值
    ///   - maxPitch: 来自歌词文件中最小值
    static func calculedScore(voicePitch: Double,
                              stdPitch: Double,
                              minPitch: Double,
                              maxPitch: Double,
                              scoreLevel: Int,
                              scoreCompensationOffset: Int) -> Float {
        if voicePitch < minPitch || voicePitch > maxPitch {
            return 0
        }
        let stdTone = ToneCalculator.pitchToTone(pitch: stdPitch)
        let voiceTone = ToneCalculator.pitchToTone(pitch: voicePitch)
        var match = 1 - Float(scoreLevel/100) * Float(abs(voiceTone - stdTone)) + Float(scoreCompensationOffset/100)
        match = max(0, match)
        match = min(1, match)
        return match * 100
    }
    
    static func pitchToTone(pitch: Double) -> Double {
        let eps = 1e-6
        return (max(0, log(pitch / 55 + eps) / log(2))) * 12
    }
}
