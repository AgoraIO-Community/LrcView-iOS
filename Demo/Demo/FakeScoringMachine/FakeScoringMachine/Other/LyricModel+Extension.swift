//
//  LyricModel+Extension.swift
//  Demo
//
//  Created by ZYP on 2024/4/23.
//

import AgoraLyricsScore

extension LyricModel {
    var minPitch: Double {
        let pitchs = lines.flatMap({ $0.tones.filter({ $0.word != " " }).map({ $0.pitch }) })
        let minValue = pitchs.min() ?? 0
        return minValue
    }
    
    var maxPitch: Double {
        let pitchs = lines.flatMap({ $0.tones.filter({ $0.word != " " }).map({ $0.pitch }) })
        let maxValue = pitchs.max() ?? 0
        return maxValue
    }
    
    func getHitedPitch(progress: UInt) -> Double? {
        let pitchBeginTime = progress
        for line in lines {
            if pitchBeginTime >= line.beginTime && pitchBeginTime <= line.beginTime + line.duration {
                for tone in line.tones {
                    if pitchBeginTime >= tone.beginTime && pitchBeginTime <= tone.beginTime + tone.duration {
                        return tone.pitch
                    }
                }
            }
        }
        return nil
    }
    
    func findCurrentIndexOfLine(progress: UInt) -> Int? {
        let lineEndTimes = lines.map({ $0.beginTime + $0.duration })
        
        if progress > lineEndTimes.last! {
            return lineEndTimes.count
        }
        
        if progress <= lineEndTimes.first! {
            return 0
        }
        
        var lastEnd: UInt = 0
        for (offset, value) in lineEndTimes.enumerated() {
            if progress > lastEnd, progress <= value  {
                return offset
            }
            lastEnd = value
        }
        return nil
    }
}
