//
//  LyricView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class LyricsView: UIView {
    /// 无歌词提示文案
    public var noLyricTipsText: String = "纯音乐，无歌词"
    /// 纯音乐 提示文字颜色
    public var noLyricTipsColor: UIColor = .orange
    /// 是否隐藏等待开始圆点
    public var waitingViewHidden: Bool = false
    /// 提示文字大小
    public var tipsFont: UIFont = .systemFont(ofSize: 17)
    /// 默认歌词背景色
    public var defaultBackgroundColor: UIColor = .gray
    /// 高亮歌词背景色
    public var highlightedBackgroundColor: UIColor = .white
    /// 正常的歌词颜色
    public var textNormalColor: UIColor = .white
    /// 实时绘制的歌词颜色
    public var textHighlightColor: UIColor = .orange
    /// 歌词文字大小
    public var textNormalFontSize: UIFont = .systemFont(ofSize: 15)
    /// 歌词高亮文字大小
    public var textHighlightFontSize: UIFont = .systemFont(ofSize: 18)
    /// 歌词最大宽度
    public var maxWidth: CGFloat = UIScreen.main.bounds.width - 30
    /// 歌词上下间距
    public var lyricLineSpacing: CGFloat = 10
    /// 等待开始圆点背景色
    public var waitingViewBackgroundColor: UIColor? = .gray
    /// 等待开始圆点大小
    public var waitingViewSize: CGFloat = 10
    /// 等待开始圆点底部间距
    public var waitingViewBottomMargin: CGFloat = 0
    /// 是否开启拖拽
    public var draggable: Bool = true
}
