//
//  TimeFix.swift
//  Demo
//
//  Created by ZYP on 2023/4/25.
//

import Foundation
import AgoraLyricsScore

public class TimeFix {
    /// 每一行歌词的信息
    public struct Line {
        var beginTime: Int
        var duration: Int
        var endTime: Int {
            return beginTime + duration
        }
    }
    
    /// 分析出合适的时间
    public static func handleFixTime(startTime: Int,
                                     endTime: Int,
                                     lines: [Line]) -> (Int, Int)? {
        if lines.isEmpty {
            return nil
        }
        
        var start = startTime
        var end = endTime
        
        if start < lines.first!.beginTime, end < lines.first!.beginTime {
            return nil
        }
        
        if start > lines.last!.beginTime + lines.last!.duration,
           end > lines.last!.beginTime + lines.last!.duration {
            return nil
        }
        
        /// 跨过第一个
        if start < lines.first!.beginTime, end < lines.first!.beginTime + lines.first!.duration {
            start = lines.first!.beginTime
            end = lines.first!.beginTime + lines.first!.duration
            return (start, end)
        }
        
        /// 跨过最后一个
        if start > lines.last!.beginTime,
           end > lines.last!.beginTime + lines.last!.duration {
            start = lines.last!.beginTime
            end = lines.last!.beginTime + lines.last!.duration
            return (start, end)
        }
        
        if start < lines.first!.beginTime {
            start = lines.first!.beginTime
        }
        
        if end > lines.last!.beginTime + lines.last!.duration {
            end = lines.last!.beginTime + lines.last!.duration
        }
        
        var preEndTime: Int?
        for line in lines {
            /** 在句子之间 **/
            if startTime >= line.beginTime,
               startTime <= line.beginTime + line.duration {
                start = line.beginTime
            }
            /** 在句子外 **/
            if let preEndTime = preEndTime {
                if start > preEndTime, start < line.beginTime {
                    start = line.beginTime
                }
            }
            
            /** 在句子之间 **/
            if endTime >= line.beginTime,
               endTime <= line.beginTime + line.duration {
                end = line.beginTime + line.duration
            }
            /** 在句子外 **/
            if let preEndTime = preEndTime {
                if end > preEndTime, end < line.beginTime {
                    end = line.beginTime + line.duration
                }
            }
            
            preEndTime = line.beginTime + line.duration
        }
        return (start, end)
    }
}
