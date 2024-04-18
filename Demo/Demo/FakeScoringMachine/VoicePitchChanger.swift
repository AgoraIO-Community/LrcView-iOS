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
        if useC {
            return handlePitchC(stdPitch, voicePitch, stdMaxPitch)
        }
        
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

        if abs(voicePitch - stdPitch) < 1 { /** 差距过小，直接返回 **/
            return voicePitch
        }

        switch n {
        case 1:
            return min(voicePitch + 0.5 * offset, stdMaxPitch)
        case 2:
            return min(voicePitch + 0.6 * offset, stdMaxPitch)
        case 3:
            return min(voicePitch + 0.7 * offset, stdMaxPitch)
        case 4:
            return min(voicePitch + 0.8 * offset, stdMaxPitch)
        case 5:
            return min(voicePitch + 0.9 * offset, stdMaxPitch)
        default:
            return min(voicePitch + offset, stdMaxPitch)
        }
    }
    
    func reset() {
        if useC {
            resetC()
            return
        }

        offset = 0.0
        n = 0.0
    }
}
