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
                    let gap = 1 /** 句间的空隙默认为1ms **/
                    lastLine.duration = line.beginTime - lastLine.beginTime - gap
                    if isEnhancedFormat {
                        if !lastLine.tones.isEmpty {
                            let duration = line.beginTime - lastLine.tones.last!.beginTime - gap
                            assert(duration >= 0)
                            lastLine.tones.last!.duration = duration
                        }
                        else {
                            Log.warning(text: "lastLine.tones isEmpty)", tag: logTag)
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
        
        let result = LyricModel(name: "unknow",
                                singer: "unknow",
                                lines: lines,
                                preludeEndPosition: preludeEndPosition,
                                duration: 0,
                                hasPitch: false,
                                sourceType: .lrc)
        return result
    }
    
    /// Checks if the string contains the start time of a word
    func containsWordStartTime(_ string: String) -> Bool {
        let pattern = "\\<\\d{2}:\\d{2}\\.\\d{3}\\>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            if let match = regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    func parseLineStringOfEnhancedFormat(_ string: String) -> [LyricToneModel] {
        let pattern = "\\<(\\d{2}):(\\d{2})\\.(\\d{3})\\>([^\\<]+)"
        var lyrics: [LyricToneModel] = []
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
            for i in 0..<matches.count {
                let match = matches[i]
                let scanner = Scanner(string: string)
                scanner.scanLocation = match.range.location
                scanner.scanString("<", into: nil)
                var beginHour = 0, beginMinute = 0, beginSecond = 0
                scanner.scanInt(&beginHour)
                scanner.scanString(":", into: nil)
                scanner.scanInt(&beginMinute)
                scanner.scanString(".", into: nil)
                scanner.scanInt(&beginSecond)
                scanner.scanString(">", into: nil)
                var word: NSString?
                scanner.scanUpTo("<", into: &word)
                
                let beginTime = (beginHour * 60 + beginMinute) * 1000 + beginSecond
                
                var endTime = 0
                if i < matches.count - 1 {
                    let nextMatch = matches[i + 1]
                    let nextScanner = Scanner(string: string)
                    nextScanner.scanLocation = nextMatch.range.location
                    nextScanner.scanString("<", into: nil)
                    var endHour = 0, endMinute = 0, endSecond = 0
                    nextScanner.scanInt(&endHour)
                    nextScanner.scanString(":", into: nil)
                    nextScanner.scanInt(&endMinute)
                    nextScanner.scanString(".", into: nil)
                    nextScanner.scanInt(&endSecond)
                    
                    endTime = (endHour * 60 + endMinute) * 1000 + endSecond
                } else {
                    endTime = beginTime // assume the last word lasts for zero second
                }
                
                let duration = endTime - beginTime
                
                if let word = word as String? {
                    let lyric = LyricToneModel(beginTime: beginTime, duration: duration, word: word, pitch: 0, lang: .zh, pronounce: "")
                    lyrics.append(lyric)
                }
            }
        }
        return lyrics
    }

    func parseTime(_ string: String) -> Int {
        let scanner = Scanner(string: string)
        var hour = 0, minute = 0, second = 0
        scanner.scanInt(&hour)
        scanner.scanString(":", into: nil)
        scanner.scanInt(&minute)
        scanner.scanString(".", into: nil)
        scanner.scanInt(&second)
        
        let time = (hour * 60 + minute) * 1000 + second
        return time
    }

}

