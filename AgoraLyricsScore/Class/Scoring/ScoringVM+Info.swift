//
//  ScoringVM+Info.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

extension ScoringVM {
    class Info {
        /// 标准开始时间 （来源自歌词文件）
        let beginTime: Int
        /// 标准时长 （来源自歌词文件）
        let duration: Int
        /// 需要绘制的开始时间
        let drawBeginTime: Int
        /// 需要绘制的时长
        var drawDuration: Int
        let word: String
        let pitch: Double
        
        init(beginTime: Int,
             duration: Int,
             word: String,
             pitch: Double,
             drawBeginTime: Int,
             drawDuration: Int) {
            self.beginTime = beginTime
            self.duration = duration
            self.word = word
            self.pitch = pitch
            self.drawBeginTime = drawBeginTime
            self.drawDuration = drawDuration
        }
        
        var endTime: Int {
            beginTime + duration
        }
        
        var drawEndTime: Int {
            drawBeginTime + drawDuration
        }
    }
    
    struct DrawInfo {
        let rect: CGRect
    }
}
