//
//  KRCParser.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2024/4/30.
//

import Foundation

public class KRCParser {
    fileprivate let logTag = "KRCParser"
    
    func parse(krcFileData: Data) -> LyricModelEx? {
        let content = String(data: krcFileData, encoding: .utf8)!
        var metadata: [String: String] = [:]
        var lineModels = [LyricLineModelEx]()
        
        /** Fix KRC文件内容中，每一行的分隔符可能是"\n"，也可能是"\r\n"，所以需要判断分隔符 **/
        var lineStrings = [String]()
        if content.contains("\r\n") {
            lineStrings = content.components(separatedBy: "\r\n")
        }
        else {
            lineStrings = content.components(separatedBy: "\n")
        }
        
        for line in lineStrings {
            /// 处理metadata部分：`[ti:星晴]`
            if line.hasPrefix("[") {
                if let range = line.range(of: ":") {
                    /// key值，从第二个字符开始取，到“:”之前
                    let key = String(line[line.index(after: line.startIndex)..<range.lowerBound])
                    /// value值，“:”之后到“]”之前
                    let value = String(line[range.upperBound..<line.index(before: line.endIndex)])
                    metadata[key] = value
                }
                else {
                    if line.contains(">"),  line.contains("<") {
                        /** Fix no offset key in krc file **/
                        var offsetValue: UInt = 0
                        if let offsetString = metadata["offset"],
                           let offset = UInt(offsetString) {
                            offsetValue = offset
                        }
                        
                        if let lineModel = parseLine(line: line, offset: offsetValue) {
                            /* check line duration valid */
                            if !lineModel.tones.isEmpty,
                               lineModel.duration != lineModel.tones.map({ $0.duration }).reduce(0, +) {
                                Log.warning(text: "line duration invalid, content:\(lineModel.content) at index:\(lineModels.count)", tag: logTag)
                            }
                            
                            lineModels.append(lineModel)
                        }
                        else {
                            Log.error(error: "parseLine error", tag: logTag)
                        }
                    }
                }
                
            }
        }
        
        return LyricModelEx(name: metadata["ti"] ?? "unknowName",
                          singer: metadata["ar"] ?? "unknowSinger",
                          type: .slow,
                          lines: lineModels,
                          preludeEndPosition: 0,
                          duration: lineModels.last?.endTime ?? 0,
                          hasPitch: false)
    }
    
    /// 解析行内容
    /// - Parameters:
    ///   - line: 行字符串, 如：`[0,1600]<0,177,0>星<177,177,0>晴<354,177,0> <531,177,0>-<708,177,0> <885,177,0>我<1062,177,0>的<1239,177,0>女<1416,177,0>孩`
    ///   - offset: metadata中的offset字段，表示时间偏移量。用于调整歌词与歌曲播放时间的同步性。
    /// - Returns: 行模型
    private func parseLine(line: String, offset: UInt) -> LyricLineModelEx? {
        guard let range = line.range(of: "["), let rangeEnd = line.range(of: "]") else {
            return nil
        }
        
        let timeStr = String(line[line.index(after: range.lowerBound)..<rangeEnd.lowerBound])
        let timeComponents = timeStr.components(separatedBy: ",")
        
        /// 处理行时间: `0,1600`
        guard timeComponents.count == 2 else {
            return nil
        }
        
        let lineStartTime = offset + (UInt(timeComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
        let lineDuration = UInt(timeComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let lineContent = line[rangeEnd.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        
        /// 解析行内容：`<0,177,0>星<177,177,0>晴<354,177,0> <531,177,0>-<708,177,0> <885,177,0>我<1062,177,0>的<1239,177,0>女<1416,177,0>孩" 转化成 LyricToneModel`
        var tones = [LyricToneModelEx]()
        let toneComponents = lineContent.components(separatedBy: "<")
        for toneComponent in toneComponents {
            if toneComponent.isEmpty {
                continue
            }
            
            /// 解析字内容： ‘0,177,0>星’
            let toneParts = toneComponent.components(separatedBy: ">")
            if toneParts.count == 2 {
                let word = toneParts[1]
                
                let timeParts = toneParts[0].components(separatedBy: ",")
                if timeParts.count == 3 {
                    let startTime = lineStartTime + (UInt(timeParts[0]) ?? 0)
                    let duration = UInt(timeParts[1]) ?? 0
                    let pitch = Double(timeParts[2]) ?? 0
                    let tone = LyricToneModelEx(beginTime: startTime,
                                              duration: duration,
                                              word: word,
                                              pitch: pitch,
                                              lang: .zh,
                                              pronounce: "")
                    
                    
                    tones.append(tone)
                }
            }
        }
        
        return LyricLineModelEx(beginTime: lineStartTime,
                              duration: lineDuration,
                              content: tones.map({ $0.word }).joined(),
                              tones: tones)
    }
}


