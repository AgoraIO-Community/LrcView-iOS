//
//  VoicePitchChanger.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/11/23.
//

import Foundation

class VoicePitchChanger {
    /// 累计的偏移值
    var offset: Double = 0.0
    /// 记录调用次数
    var n: Double = 0
    
    /// 处理Pitch
    /// - Parameters:
    ///   - stdPitch: 标准值 来自歌词文件
    ///   - voicePitch: 实际值 来自rtc回调
    ///   - stdMaxPitch: 最大值 来自标准值
    /// - Returns: 处理后的值
    func handlePitch(stdPitch: Double,
                     voicePitch: Double,
                     stdMaxPitch: Double) -> Double {
        if voicePitch <= 0 {
            return 0
        }
        
        n += 1.0
        let gap = stdPitch - voicePitch
        
        offset = offset * (n - 1)/n + gap/n
        
        if offset < 0 {
            offset = max(offset, -1 * stdMaxPitch * 0.4)
        }
        else {
            offset = min(offset, stdMaxPitch * 0.4)
        }
        
        if abs(ToneCalculator.pitchToTone(pitch: voicePitch) - ToneCalculator.pitchToTone(pitch: stdPitch)) < 0.5 { /** tone差距过小，直接返回 **/
            return voicePitch
        }
        
        return min(voicePitch + offset, stdMaxPitch)
    }
    
    func reset() {
        offset = 0.0
        n = 0.0
    }
}
