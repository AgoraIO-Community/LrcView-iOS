//
//  LyricCellProtocol.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2025/3/10.
//

import Foundation

protocol LyricCellProtocol: UITableViewCell {
    /// 正常歌词背景色
    var textNormalColor: UIColor { get set}
    /// 选中的歌词颜色
    var textSelectedColor: UIColor { get set}
    /// 高亮的歌词填充颜色
    var textHighlightedColor: UIColor { get set}
    /// 正常歌词文字大小
    var textNormalFontSize: UIFont { get set}
    /// 高亮歌词文字大小
    var textHighlightFontSize: UIFont { get set}
    /// 上下间距
    var lyricLineSpacing: CGFloat { get set}
    
    func update(model: LyricCellModel)
}


class LyricCellModel {
    let text: String
    /// 进度 0-1
    var progressRate: Double
    /// 开始时间 单位为毫秒
    let beginTime: UInt
    /// 总时长 (ms)
    let duration: UInt
    /// 状态
    var status: Status
    
    var tones: [LyricToneModel]
    
    init(text: String,
         progressRate: Double,
         beginTime: UInt,
         duration: UInt,
         status: Status,
         tones: [LyricToneModel]) {
        self.text = text
        self.progressRate = progressRate
        self.beginTime = beginTime
        self.duration = duration
        self.status = status
        self.tones = tones
    }
    
    func update(progressRate: Double) {
        self.progressRate = progressRate
    }
    
    func update(status: Status) {
        self.status = status
    }
    
    var endTime: UInt {
        beginTime + duration
    }
}

typealias Status = LysicLabelStatus

