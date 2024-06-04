//
//  Model.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import Foundation

struct KrcPitchData: Codable {
    let pitch: Double
    let startTime: UInt
    let duration: UInt
}

@objc public enum LyricsType: Int8, CustomStringConvertible {
    case xml = 1
    case lrc = 2
    case krc = 3
    
    public var description: String {
        switch self {
        case .xml:
            return "xml"
        case .lrc:
            return "lrc"
        case .krc:
            return "krc"
        }
    }
}

public class LyricModel: NSObject {
    /// 歌曲名称
    @objc public var name: String
    /// 歌星名称
    @objc public var singer: String
    
    @objc public var lyricsType: LyricsType
    /// 行信息
    @objc public var lines: [LyricLineModel]
    /// 前奏结束时间
    @objc public var preludeEndPosition: UInt
    /// 歌词总时长 (ms)
    @objc public var duration: UInt
    /// 是否有pitch值
    @objc public var hasPitch: Bool
    
    @objc public var copyrightSentenceLineCount: UInt = 0
    
    var pitchDatas: [KrcPitchData] = []
    
    @objc public init(name: String,
                      singer: String,
                      lyricsType: LyricsType,
                      lines: [LyricLineModel],
                      preludeEndPosition: UInt,
                      duration: UInt,
                      hasPitch: Bool) {
        self.name = name
        self.singer = singer
        self.lyricsType = lyricsType
        self.lines = lines
        self.preludeEndPosition = preludeEndPosition
        self.duration = duration
        self.hasPitch = hasPitch
    }
    
    @objc public override var description: String {
        let dict = ["name" : name,
                    "singer" : singer,
                    "type" : lyricsType,
                    "preludeEndPosition" : preludeEndPosition,
                    "duration" : duration,
                    "hasPitch" : hasPitch] as [String : Any]
        return "\(dict)"
    }
}

public class LyricLineModel: NSObject {
    /// 开始时间 单位为毫秒
    @objc public var beginTime: UInt
    /// 总时长 (ms)
    @objc public var duration: UInt
    /// 行内容
    @objc public var content: String
    /// 每行歌词的字信息
    @objc public var tones: [LyricToneModel]
    
    @objc public init(beginTime: UInt,
                      duration: UInt,
                      content: String,
                      tones: [LyricToneModel]) {
        self.beginTime = beginTime
        self.duration = duration
        self.content = content
        self.tones = tones
    }
}

public class LyricToneModel: NSObject {
    @objc public let beginTime: UInt
    @objc public let duration: UInt
    @objc public var word: String
    @objc public let pitch: Double
    @objc public var lang: Lang
    @objc public let pronounce: String
    
    @objc public init(beginTime: UInt,
                      duration: UInt,
                      word: String,
                      pitch: Double,
                      lang: Lang,
                      pronounce: String) {
        self.beginTime = beginTime
        self.duration = duration
        self.word = word
        self.pitch = pitch
        self.lang = lang
        self.pronounce = pronounce
    }
}

/// 字得分
public class ToneScoreModel: NSObject {
    @objc public let tone: LyricToneModel
    /// 0-100
    @objc public var score: Float
    var scores = [Float]()
    
    @objc public init(tone: LyricToneModel,
                      score: Float) {
        self.tone = tone
        self.score = score
    }
    
    func addScore(score: Float) {
        scores.append(score)
        self.score = scores.reduce(0, +) / Float(scores.count)
    }
}

@objc public enum Lang: Int {
    case zh = 1
    case en = 2
    case unknown = -1
}

