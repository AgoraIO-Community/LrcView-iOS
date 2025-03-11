//
//  LysicLabelProtocol.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2025/3/10.
//

public enum LysicLabelStatus {
    case normal
    case selectedOrHighlighted
}

protocol LysicLabelProtocol {
    /// [0, 1]
    var progressRate: CGFloat { get set }
    /// 正常歌词颜色
    var textNormalColor: UIColor { get set }
    /// 选中的歌词颜色
    var textSelectedColor: UIColor { get set }
    /// 高亮的歌词颜色
    var textHighlightedColor: UIColor { get set }
    /// 正常歌词文字大小
    var textNormalFontSize: UIFont { get set }
    /// 高亮歌词文字大小
    var textHighlightFontSize: UIFont { get set }
    /// 状态
    var status: LysicLabelStatus { get set }
}
