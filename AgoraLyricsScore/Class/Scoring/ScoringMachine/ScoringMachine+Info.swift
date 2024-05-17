//
//  ScoringVM+Info.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

extension ScoringMachine {
    class Info {
        /// 标准开始时间 （来源自歌词文件）
        let beginTime: UInt
        /// 标准时长 （来源自歌词文件）
        let duration: UInt
        /// 需要绘制的开始时间
        let drawBeginTime: UInt
        /// 需要绘制的时长
        var drawDuration: UInt
        let word: String
        let pitch: Double
        /// 是否句子中最后的一个字
        
        
        required init(beginTime: UInt,
                      duration: UInt,
                      word: String,
                      pitch: Double,
                      drawBeginTime: UInt,
                      drawDuration: UInt) {
            self.beginTime = beginTime
            self.duration = duration
            self.word = word
            self.pitch = pitch
            self.drawBeginTime = drawBeginTime
            self.drawDuration = drawDuration
        }
        
        var endTime: UInt {
            beginTime + duration
        }
        
        var drawEndTime: UInt {
            drawBeginTime + drawDuration
        }
        
        var tone: LyricToneModelEx {
            return LyricToneModelEx(beginTime: beginTime,
                                  duration: duration,
                                  word: word,
                                  pitch: pitch,
                                  lang: .zh,
                                  pronounce: "")
        }
    }
    
    struct DrawInfo {
        let rect: CGRect
    }
    
    struct DebugInfo {
        /// 原始pitch
        let originalPitch: Double
        /// 男女音调算法改变后的pitch
        let pitch: Double
        let hitedInfo: ScoringMachine.Info?
        let progress: UInt
    }
}


