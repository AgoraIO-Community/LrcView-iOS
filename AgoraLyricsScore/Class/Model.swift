//
//  Model.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import Foundation

// MARK: - Public
@objc public enum MusicType: Int, CustomStringConvertible {
    case unknow = 0
    /// 快歌
    case fast = 1
    /// 慢歌
    case slow = 2
    
    public var description: String {
        switch self {
        case .fast:
            return "fast"
        case .slow:
            return "slow"
        default:
            return "unknow"
        }
    }
}

public class LyricModel: NSObject {
    /// 歌曲名称
    @objc public var name: String
    /// 歌星名称
    @objc public var singer: String
    /// 歌曲类型
    @objc public var type: MusicType
    /// 行信息
    @objc public var lines: [LyricLineModel]
    /// 前奏结束时间
    @objc public var preludeEndPosition: Int
    /// 歌词总时长 (ms)
    @objc public var duration: Int
    /// 是否有pitch值
    @objc public var hasPitch: Bool
    
    /// 歌曲时间是否准确到歌词的每一个字
    @objc public let isTimeAccurateToWord: Bool
    
    @objc public init(name: String,
                      singer: String,
                      type: MusicType,
                      lines: [LyricLineModel],
                      preludeEndPosition: Int,
                      duration: Int,
                      hasPitch: Bool,
                      isTimeAccurateToWord: Bool) {
        self.name = name
        self.singer = singer
        self.type = type
        self.lines = lines
        self.preludeEndPosition = preludeEndPosition
        self.duration = duration
        self.hasPitch = hasPitch
        self.isTimeAccurateToWord = isTimeAccurateToWord
    }
    
    @objc public override init() {
        self.name = ""
        self.singer = ""
        self.type = .fast
        self.lines = []
        self.preludeEndPosition = 0
        self.duration = 0
        self.hasPitch = false
        self.isTimeAccurateToWord = false
        super.init()
    }
    
    @objc public override var description: String {
        let dict = ["name" : name,
                    "singer" : singer,
                    "type" : type,
                    "preludeEndPosition" : preludeEndPosition,
                    "duration" : duration,
                    "hasPitch" : hasPitch] as [String : Any]
        return "\(dict)"
    }
}

public class LyricLineModel: NSObject {
    /// 开始时间 单位为毫秒
    @objc public var beginTime: Int
    /// 总时长 (ms)
    @objc public var duration: Int
    /// 行内容
    @objc public var content: String
    /// 每行歌词的字信息
    @objc public var tones: [LyricToneModel]
    
    @objc public init(beginTime: Int,
                      duration: Int,
                      content: String,
                      tones: [LyricToneModel]) {
        self.beginTime = beginTime
        self.duration = duration
        self.content = content
        self.tones = tones
    }
}

public class LyricToneModel: NSObject {
    @objc public let beginTime: Int
    @objc public let duration: Int
    @objc public var word: String
    @objc public var pitch: Double
    @objc public var lang: Lang
    @objc public let pronounce: String
    
    @objc public init(beginTime: Int,
                      duration: Int,
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
    case unknow = -1
}

// MARK: - Internal

struct PitchModel {
    let version: Int
    let timeInterval: Int
    let reserved: Int
    let duration: Int
    let items: [PitchItem]
}

struct PitchItem {
    let value: Double
    let beginTime: Int
    let duration: Int
    var endTime: Int { beginTime + duration }
}
