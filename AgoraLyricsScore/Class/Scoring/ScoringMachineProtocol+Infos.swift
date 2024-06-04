//
//  ScoringMachineProtocol+Infos.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2024/6/4.
//

import Foundation

class ScoringMachineInfo {
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
    
    var tone: LyricToneModel {
        return LyricToneModel(beginTime: beginTime,
                              duration: duration,
                              word: word,
                              pitch: pitch,
                              lang: .zh,
                              pronounce: "")
    }
}

struct ScoringMachineDrawInfo {
    let rect: CGRect
}

struct ScoringMachineDebugInfo {
    /// 原始pitch
    let originalPitch: Double
    /// 男女音调算法改变后的pitch
    let pitch: Double
    let hitedInfo: ScoringMachineInfo?
    let progress: UInt
}
