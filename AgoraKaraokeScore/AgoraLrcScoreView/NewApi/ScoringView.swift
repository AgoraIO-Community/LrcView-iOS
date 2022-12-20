//
//  ScoringView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class ScoringView: UIView {
    /// 评分视图高度
    public var viewHeight: CGFloat = 100
    /// 游标的起始位置
    public var defaultPitchCursorX: CGFloat = 100
    /// 音准线的高度
    public var standardPitchStickViewHeight: CGFloat = 10
    /// 音准线的基准因子
    public var movingSpeedFactor: CGFloat = 120
    /// 音准线默认的背景色
    public var standardPitchStickViewColor: UIColor = .gray
    /// 音准线匹配后的背景色
    public var standardPitchStickViewHighlightColor: UIColor = .orange
    /// 分割线的颜色
    public var separatorColor: UIColor = .systemPink
    /// 是否隐藏垂直分割线
    public var isVerticalSeparatorLineHidden: Bool = false
    /// 是否隐藏上下分割线
    public var separatorHidden: Bool = false
    /// 游标背景色
    public var localPitchCursorColor: UIColor = .systemPink
    /// 游标的半径
    public var localPitchCursorRadius: CGFloat = 20
    /// 是否隐藏粒子动画效果
    public var particleEffectHidden: Bool = false
    /// 使用图片创建粒子动画
    public var emitterImages: [UIImage]?
    /// 动画颜色 (emitterImages为空时，默认使用颜色创建粒子动画)
    public var emitterColors: [UIColor] = [.red]
    /// 自定义火焰效果图片
    public var fireEffectImage: UIImage?
    /// 火焰效果颜色 图片为空时使用颜色
    public var fireEffectColor: UIColor? = .yellow
    /// 是否隐藏等级视图
    public var isRankViewHidden: Bool = false
    /// 等级视图高
    public var gradeViewHeight: CGFloat = 20
    /// 等级视图宽
    public var gradeViewWidth: CGFloat = 200
    /// 等级视图的正常颜色
    public var gradeViewNormalColor: UIColor = .gray
    /// 等级视图的高亮颜色 (渐变色)
    public var gradeViewHighlightColors: [UIColor] = [.blue]
    /// 评分激励是否显示
    public var incentiveViewHidden: Bool = false
    /// 评分激励的文字颜色 (渐变色)
    public var incentiveTextColor: [UIColor] = [.blue]
    /// 评分激励的文字大小
    public var incentiveTextFont: UIFont = .systemFont(ofSize: 18)
}
