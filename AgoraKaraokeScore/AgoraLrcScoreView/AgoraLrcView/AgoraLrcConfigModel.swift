//
//  AgoraLrcConfigModel.swift
//  AgoraKaraokeScore
//
//  Created by zhaoyongqiang on 2021/12/17.
//

import UIKit

@objcMembers
public class AgoraLrcConfigModel: NSObject {
    /// 无歌词提示文案
    public var tipsString: String = "纯音乐，无歌词"
    /// 提示文字颜色
    public var tipsColor: UIColor = .orange
    /// 提示文字大小
    public var tipsFont: UIFont = .systemFont(ofSize: 17)
    /// 分割线的颜色
    public var separatorLineColor: UIColor = .lightGray
    /// 是否隐藏分割线
    public var isHiddenSeparator: Bool = false
    /// 默认歌词背景色
    public var lrcNormalColor: UIColor = .gray
    /// 高亮歌词背景色
    public var lrcHighlightColor: UIColor = .white
    /// 实时绘制的歌词颜色
    public var lrcDrawingColor: UIColor = .orange
    /// 歌词文字大小 默认: 15
    public var lrcFontSize: UIFont = .systemFont(ofSize: 15)
    /// 歌词高亮文字大小 默认: 18
    public var lrcHighlightFontSize: UIFont = .systemFont(ofSize: 18)
    /// 歌词最大宽度
    public var maxWidth: CGFloat = UIScreen.main.bounds.width - 30
    /// 歌词上下间距
    public var lrcTopAndBottomMargin: CGFloat = 10
    /// 是否隐藏等待开始圆点
    public var isHiddenWatitingView: Bool = false
    /// 等待开始圆点背景色 默认: 灰色
    public var waitingViewBgColor: UIColor? = .gray
    /// 等待开始圆点大小 默认: 10
    public var waitingViewSize: CGFloat = 10
    /// 等待开始圆点底部间距
    public var waitingViewBottomMargin: CGFloat = 0
    /// 是否可以拖动歌词 默认: true,  如果开启评分功能,禁止拖动
    public var isDrag: Bool = true
    /// 底部蒙层颜色
    public var bottomMaskColors: [UIColor] = [UIColor(white: 0, alpha: 0.05),
                                              UIColor(white: 0, alpha: 0.8)]
    /// 蒙层位置
    public var bottomMaskLocations: [NSNumber] = [0.7, 1.0]
    /// 蒙层高度, 默认: 视图的高
    public var bottomMaskHeight: CGFloat = 0
    /// 是否隐藏底部蒙层
    public var isHiddenBottomMask: Bool = false
    /// 歌词滚动位置
    public var lyricsScrollPosition: UITableView.ScrollPosition = .middle
}
