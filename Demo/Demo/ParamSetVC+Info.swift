//
//  ParamSetVC+Info.swift
//  Demo
//
//  Created by ZYP on 2023/1/31.
//

import UIKit
import AgoraLyricsScore

struct Section {
    let title: String
    let rows: [Row]
}

struct Row {
    let title: String
}

class Param {
    static let `default` = Param()
    
    let karaoke = KaraokeViewParam()
    let lyric = LyricViewParam()
    let scoring = ScoringViewParam()
}

class KaraokeViewParam {
    /// 背景图
    var backgroundImage: UIImage? = UIImage(named: "ktv_top_bgIcon")
    
    /// 是否使用评分功能
    /// - Note: 当`LyricModel.hasPitch = false`，强制不使用
    /// - Note: 当为 `false`, 会隐藏评分视图
    var scoringEnabled: Bool = true
    
    /// 评分组件和歌词组件之间的间距 默认: 0
    var spacing: CGFloat = 0
    
    var scoreLevel = 15
    var scoreCompensationOffset = 0
}

class LyricViewParam {
    /// 无歌词提示文案
    var noLyricTipsText: String = "无歌词"
    /// 无歌词提示文字颜色
    var noLyricTipsColor: UIColor = .orange
    /// 无歌词提示文字大小
    var noLyricTipsFont: UIFont = .systemFont(ofSize: 17)
    /// 是否隐藏等待开始圆点
    var waitingViewHidden: Bool = false
    /// 正常歌词颜色
    var inactiveLineTextColor: UIColor = .white
    /// 选中的歌词颜色
    var activeLineUpcomingTextColor: UIColor = .white
    /// 高亮的歌词颜色 （命中）
    var activeLinePlayedTextColor: UIColor = .colorWithHex(hexStr: "#FF8AB4")
    /// 正常歌词文字大小
    var inactiveLineFontSize = UIFont(name: "PingFangSC-Semibold", size: 15)!
    /// 高亮歌词文字大小
    var activeLineUpcomingFontSize = UIFont(name: "PingFangSC-Semibold", size: 18)!
    /// 歌词上下间距
    var lyricLineSpacing: CGFloat = 10
    /// 等待开始圆点风格
    var firstToneHintViewStyle: FirstToneHintViewStyle = .init()
    /// 是否开启拖拽
    var draggable: Bool = false
}

class ScoringViewParam {
    /// 评分视图高度
    var viewHeight: CGFloat = 100
    /// 渲染视图到顶部的间距
    var topSpaces: CGFloat = 80
    /// 游标的起始位置
    var defaultPitchCursorX: CGFloat = 100
    /// 音准线的高度
    var standardPitchStickViewHeight: CGFloat = 3
    /// 音准线的基准因子
    var movingSpeedFactor: CGFloat = 120
    /// 音准线默认的背景色
    var standardPitchStickViewColor: UIColor = .gray
    /// 音准线匹配后的背景色
    var standardPitchStickViewHighlightColor: UIColor = .orange
    /// 是否隐藏粒子动画效果
    var particleEffectHidden: Bool = false
    /// 使用图片创建粒子动画
    var emitterImages: [UIImage]?
    /// 打分容忍度 范围：0-1
    var hitScoreThreshold: Float = 0.7
    /// use for debug only
    var showDebugView = false
}

extension UIColor {
    static var random: UIColor {
        UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
    }
}


extension UIColor {
    class func colorWithHex(hexStr:String) -> UIColor{
        return UIColor.colorWithHex(hexStr : hexStr, alpha:1)
    }
    
    class func colorWithHex(hexStr:String, alpha:Float) -> UIColor{
        
        var cStr = hexStr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased() as NSString;
        
        if(cStr.length < 6){
            return UIColor.clear;
        }
        
        if(cStr.hasPrefix("0x")){
            cStr = cStr.substring(from: 2) as NSString
        }
        
        if(cStr.hasPrefix("#")){
            cStr = cStr.substring(from: 1) as NSString
        }
        
        if(cStr.length != 6){
            return UIColor.clear
        }
        
        let rStr = (cStr as NSString).substring(to: 2)
        let gStr = ((cStr as NSString).substring(from: 2) as NSString).substring(to: 2)
        let bStr = ((cStr as NSString).substring(from: 4) as NSString).substring(to: 2)
        
        var r: UInt32 = 0x0
        var g: UInt32 = 0x0
        var b: UInt32 = 0x0
        
        Scanner.init(string: rStr).scanHexInt32(&r)
        Scanner.init(string: gStr).scanHexInt32(&g)
        Scanner.init(string: bStr).scanHexInt32(&b)
        
        return UIColor.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: CGFloat(alpha));
        
    }
}
