//
//  VoicePitchChanger.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/11/23.
//

import Foundation


class VoicePitchChanger {
    var offset: Double = 0.0
    var n: Double = 0
    
    /// 处理Picth
    /// - Parameters:
    ///   - wordPitch: 标准值 来自歌词文件
    ///   - voicePitch: 实际值 来自rtc回调
    ///   - wordMaxPitch: 最大值 来自标准值
    /// - Returns: 处理后的值
    func handlePitch(wordPitch: Double,
                     voicePitch: Double,
                     wordMaxPitch: Double) -> Double {
        if voicePitch <= 0 {
            return 0
        }
        
        n += 1.0
        let gap = wordPitch - voicePitch
        
        offset = offset * (n - 1)/n + gap/n
        
        if offset < 0 {
            offset = max(offset, -1 * wordMaxPitch * 0.4)
        }
        else {
            offset = min(offset, wordMaxPitch * 0.4)
        }
        
        return voicePitch + offset
    }
    
    func reset() {
        offset = 0.0
        n = 0.0
    }
}
