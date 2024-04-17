//
//  Model.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import Foundation

@objc public enum MusicType: Int, CustomStringConvertible {
    /// 快歌
    case fast = 1
    /// 慢歌
    case slow = 2
    
    public var description: String {
        switch self {
        case .fast:
            return "fast"
        default:
            return "slow"
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
    
    @objc public init(name: String,
                      singer: String,
                      type: MusicType,
                      lines: [LyricLineModel],
                      preludeEndPosition: Int,
                      duration: Int,
                      hasPitch: Bool) {
        self.name = name
        self.singer = singer
        self.type = type
        self.lines = lines
        self.preludeEndPosition = preludeEndPosition
        self.duration = duration
        self.hasPitch = hasPitch
    }
    
    /// 解析歌词文件xml数据
    /// - Parameter data: xml二进制数据
    /// - Returns: 歌词信息
    @objc public init(data: Data) throws {
        self.name = "name"
        self.singer = "singer"
        self.type = .fast
        self.lines = []
        self.preludeEndPosition = 0
        self.duration = 0
        self.hasPitch = true
    }
    
    @objc public override init() {
        self.name = ""
        self.singer = ""
        self.type = .fast
        self.lines = []
        self.preludeEndPosition = 0
        self.duration = 0
        self.hasPitch = false
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
    @objc public let pitch: Double
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



@objc public enum Lang: Int {
    case zh = 1
    case en = 2
    case unknown = -1
}

