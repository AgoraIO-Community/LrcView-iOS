//
//  File.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

class Parser {
    private let logTag = "Parser"
    func parseLyricData(data: Data,
                        pitchFileData: Data? = nil,
                        includeCopyrightSentence: Bool = false) -> LyricModel? {
        guard data.count > 0 else {
            Log.errorText(text: "data.count == 0", tag: logTag)
            return nil
        }
        
        let format = detectLyricFormat(from: data)
        
        switch format {
        case .krc:
            let parser = KRCParser()
            return parser.parse(krcFileData: data,
                                pitchFileData: pitchFileData,
                                includeCopyrightSentence: includeCopyrightSentence)
        case .xml:
            let parser = XmlParser()
            return parser.parseLyricData(data: data)
        case .lrc:
            let parser = LrcParser()
            return parser.parseLyricData(data: data)
        case .unknown:
            Log.errorText(text: "unknow file type", tag: logTag)
            return nil
        }
    }

    enum LyricFormat {
        case lrc
        case krc
        case xml
        case unknown
    }

    func detectLyricFormat(from data: Data) -> LyricFormat {
        // 将Data类型转换为String
        guard let string = String(data: data, encoding: .utf8) else {
            return .unknown
        }
        
        // 检测LRC格式的特征，通常是时间戳和歌词行
        // 正则表达式匹配LRC格式的时间戳
        let lrcPattern = "\\[\\d{2}:\\d{2}\\.\\d{2}\\]"
        if let _ = string.range(of: lrcPattern, options: .regularExpression) {
            return .lrc
        }
        
        // 检测KRC格式的特征，通常是特定的标签如[id:$xxxxxxxx]
        let krcPattern = "\\[(\\w+):([^]]*)]"
        if let _ = string.range(of: krcPattern, options: .regularExpression) {
            return .krc
        }
        
        // 检测XML格式的特征，即XML的开始标签
        if string.contains("<?xml") {
            return .xml
        }
        
        /// 无文件头的xml
        if string.contains("<song>"), string.contains("<paragraph>") {
            return .xml
        }
        
        // 如果没有匹配的特征，返回unknown
        return .unknown
    }
    
    
}
