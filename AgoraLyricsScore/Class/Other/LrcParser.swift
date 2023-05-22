//
//  LrcParser.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

class LrcParser {
    private let logTag = "LrcParser"
    private var lines = [LyricLineModel]()
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    func parseLyricData(data: Data) -> LyricModel? {
        lines = []
        guard let string = String(data: data, encoding: .utf8) else {
            Log.errorText(text: "convert to string fail", tag: logTag)
            return nil
        }
        return parse(lrcString: string)
    }
    
    private func parse(lrcString: String) -> LyricModel? {
        let sep = lrcString.contains("\r\n") ? "\r\n" : "\n"
        let lrcConnectArray = lrcString.components(separatedBy: sep).filter({ !$0.isEmpty })
        
        let pattern = "\\[[0-9][0-9]:[0-9][0-9].[0-9]{1,}\\]"
        guard let regular = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        for line in lrcConnectArray {
            let matchesArray = regular.matches(in: line,
                                               options: .reportProgress,
                                               range: NSRange(location: 0, length: line.count))
            guard let lrc = line.components(separatedBy: "]").last else {
                continue
            }
            
            for match in matchesArray {
                var timeStr = NSString(string: line).substring(with: match.range)
                // 去掉开头和结尾的[], 得到时间00:00.00
                timeStr = timeStr.textSubstring(startIndex: 1, length: timeStr.count - 2)
                
                let df = DateFormatter()
                df.dateFormat = "mm:ss.SS"
                let date1 = df.date(from: timeStr)
                let date2 = df.date(from: "00:00.00")
                var interval1 = date1!.timeIntervalSince1970
                let interval2 = date2!.timeIntervalSince1970
                
                interval1 -= interval2
                if interval1 < 0 {
                    interval1 *= -1
                }
                
                let line = LyricLineModel(beginTime: Int(interval1 * 1000),
                                          duration: 0,
                                          content: lrc,
                                          tones: [])
                if let lastLine = lines.last { /** 把上一句的时间补齐 **/
                    let gap = 1 /** 句间的空隙默认为1ms **/
                    lastLine.duration = line.beginTime - lastLine.beginTime - gap
                    if lastLine.duration <= 0 {
                        Log.warning(text: "lastLine.duration = \(lastLine.duration)", tag: logTag)
                    }
                }
                lines.append(line)
            }
        }
        
        guard lines.count != 0, let preludeEndPosition = lines.first?.beginTime else {
            return nil
        }
        
        let result = LyricModel(name: "unknow",
                                singer: "unknow",
                                type: .unknow,
                                lines: lines,
                                preludeEndPosition: preludeEndPosition,
                                duration: 0,
                                hasPitch: false,
                                isTimeAccurateToWord: false)
        return result
    }
}

