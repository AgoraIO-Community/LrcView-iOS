//
//  LrcParser.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

/** A class that can parse two formats of lrc lyrics files:
 - 1. Simple lrc format, which contains the start time and the whole line of lyrics for each line, such as:
 ```
 [00:22.30]我不会发现 我难受
 [00:25.745]怎么说出口
 [00:29.284]也不过是分手
 ```
 - 2. Enhanced lrc format, which contains the start time and the end time for each word of lyrics, such as:
 ```
 [00:23.997]<00:23.997>又<00:24.694>是<00:25.356>九<00:25.704>月<00:26.017>九<00:26.644>重<00:27.028>阳<00:27.376>夜<00:28.003>难<00:28.351>聚<00:28.665>首
 [00:29.326]<00:29.326>思<00:30.023>乡<00:30.476>的<00:30.719>人<00:31.416>儿<00:32.008>飘<00:32.322>流<00:32.705>在<00:33.053>外<00:33.332>头
 [00:34.690]<00:34.690>又<00:35.352>是<00:36.014>九<00:36.327>月<00:36.675>九<00:37.337>愁<00:37.685>更<00:38.034>愁<00:38.661>情<00:39.009>更<00:39.392>忧
 ```
 **/
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
                
                let beginTime = parseTime(timeStr)
                
                var content = lrc
                var tones = [LyricToneModel]()
                
                let isEnhancedFormat = containsWordStartTime(lrc)
                if isEnhancedFormat { /** enhanced format **/
                    tones = parseLineStringOfEnhancedFormat(line)
                    content = tones.map({ $0.word }).joined()
                }
                
                let line = LyricLineModel(beginTime: beginTime,
                                          duration: 0,
                                          content: content,
                                          tones: tones)
                if let lastLine = lines.last { /** 把上一句的时间补齐 **/
                    let gap: UInt = 1 /** 句间的空隙默认为1ms **/
                    if line.beginTime > lastLine.beginTime {
                        lastLine.duration = line.beginTime - lastLine.beginTime - gap
                    }
                    else {
                        Log.errorText(text: "calculate duration error, line.beginTime:\(line.beginTime), lastLine.beginTime:\(lastLine.beginTime), in content `\(line)`, matchesArray.count:\(matchesArray.count)", tag: logTag)
                        lastLine.duration = 0
                    }
                    if isEnhancedFormat {
                        if !lastLine.tones.isEmpty {
                            let duration = line.beginTime - lastLine.tones.last!.beginTime - gap
                            if duration <= 0 {
                                Log.errorText(text: " duration <= 0", tag: logTag)
                            }
                            lastLine.tones.last!.duration = max(0, duration)
                        }
                        else {
                            Log.warning(text: "lastLine.tones isEmpty", tag: logTag)
                        }
                    }
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
        let duration: UInt = lines.last?.endTime ?? 0
        let result = LyricModel(name: "unknow",
                                singer: "unknow",
                                lyricsType: .lrc,
                                lines: lines,
                                preludeEndPosition: preludeEndPosition,
                                duration: duration,
                                hasPitch: false)
        return result
    }
    
    /// Checks if the string contains the start time of a word
    func containsWordStartTime(_ string: String) -> Bool {
        let pattern = "\\<\\d{2}:\\d{2}\\.\\d{3}\\>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            if (regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) != nil)  {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func parseLineStringOfEnhancedFormat(_ string: String) -> [LyricToneModel] {
        var toneModels = [LyricToneModel]()
        
        /// "[00:53.011]<00:53.011> Why<00:53.011> hh" ==>  ["00:53.011> Why", "00:53.011> hh"]
        let strs = string.components(separatedBy: "<").filter({ $0.contains(">") })
        for str in strs {
            /// "00:53.011> Why"
            let components = str.components(separatedBy: ">")
            let beginTime = parseTime(components[0])
            let text = components[1]
            let toneModel = LyricToneModel(beginTime: beginTime,
                                           duration: 0,
                                           word: text,
                                           pitch: 0,
                                           lang: .unknown,
                                           pronounce: "")
            
            /// 计算上一个的duration
            if !toneModels.isEmpty {
                let lastToneModel = toneModels.last!
                let duration = toneModel.beginTime - lastToneModel.beginTime
                lastToneModel.duration = duration
            }
            
            toneModels.append(toneModel)
        }
        
        return toneModels
    }
    
    func parseTime(_ string: String) -> UInt {
        let scanner = Scanner(string: string)
        var hour = 0, minute = 0, second = 0
        scanner.scanInt(&hour)
        scanner.scanString(":", into: nil)
        scanner.scanInt(&minute)
        scanner.scanString(".", into: nil)
        scanner.scanInt(&second)
        let time = (hour * 60 + minute) * 1000 + second
        return UInt(time)
    }
    
}

