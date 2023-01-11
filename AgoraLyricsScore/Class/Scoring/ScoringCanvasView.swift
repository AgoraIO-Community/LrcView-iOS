//
//  ScoringCanvasView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/3.
//

import UIKit

class ScoringCanvasView: UIView {
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
    /// 分割线的颜色
    var separatorColor: UIColor = .systemPink
    /// 是否隐藏垂直分割线
    var isVerticalSeparatorLineHidden: Bool = false
    /// 是否隐藏上下分割线
    var separatorHidden: Bool = false
    
    fileprivate var standardInfos = [DrawInfo]()
    fileprivate var highlightInfos = [DrawInfo]()
    fileprivate var widthPreMs: CGFloat { movingSpeedFactor / 1000 }
    
    override func draw(_ rect: CGRect) {
        drawStaff()
        drawStandardInfos()
        drawHighlightInfos()
    }
    
    func draw(standardInfos: [DrawInfo],
              highlightInfos: [DrawInfo]) {
        self.standardInfos = standardInfos
        self.highlightInfos = highlightInfos
        setNeedsDisplay()
    }
    
    func reset() {
        self.standardInfos = []
        self.highlightInfos = []
        setNeedsDisplay()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Draw
extension ScoringCanvasView {
    /// 五线谱
    fileprivate func drawStaff() {
        let height = bounds.height
        let width = bounds.width
        let lineHeight: CGFloat = 1
        let spaceY = (height - lineHeight * 5) / 4
        
        for i in 0...5 {
            let y = CGFloat(i) * (spaceY + lineHeight)
            let rect = CGRect(x: 0, y: y, width: width, height: lineHeight)
            let linePath = UIBezierPath(rect: rect)
            UIColor.white.withAlphaComponent(0.08).setFill()
            linePath.fill()
        }
    }
    
    fileprivate func drawStandardInfos() {
        drawInfos(infos: standardInfos, fillColor: standardPitchStickViewColor)
    }
    
    fileprivate func drawHighlightInfos() {
        drawInfos(infos: highlightInfos, fillColor: standardPitchStickViewHighlightColor)
    }
    
    private func drawInfos(infos: [DrawInfo], fillColor: UIColor) {
        for info in infos {
            let rect = info.rect
            let path = UIBezierPath(roundedRect: rect, cornerRadius: standardPitchStickViewHeight/2)
            fillColor.setFill()
            path.fill()
        }
    }
    
//    private func drawInfos(infos: [ScoringVM.Info], fillColor: UIColor) {
//        for info in infos {
//            let beginTime = info.drawBeginTime
//            let duration = info.drawDuration
//            let pitch = info.pitch
//
//            /// 视图最左边到游标这段距离对应的时长
//            let defaultPitchCursorXTime = Int(defaultPitchCursorX / widthPreMs)
//            let x = CGFloat(beginTime - (progress - defaultPitchCursorXTime)) * widthPreMs
//            let y = getCenterY(pitch: pitch) - (standardPitchStickViewHeight / 2)
//            let w = widthPreMs * CGFloat(duration)
//            let h = standardPitchStickViewHeight
//            let rect = CGRect(x: x, y: y, width: w, height: h)
//            let path = UIBezierPath(roundedRect: rect, cornerRadius: standardPitchStickViewHeight/2)
//            fillColor.setFill()
//            path.fill()
//        }
//    }
    
    /// 计算y的位置
//    private func getCenterY(pitch: Double) -> CGFloat {
//        if pitch <= 0 {
//            return bounds.height
//        }
//        if pitch < minPitch { return bounds.height }
//        if pitch > maxPitch { return 0 }
//
//        /// 映射成从0开始
//        let value = pitch - minPitch
//        /// 计算相对偏移
//        let distance = (value / (maxPitch - minPitch)) * bounds.height
//        let y = bounds.height - distance
//        return y
//    }
}

extension ScoringCanvasView {
    typealias DrawInfo = ScoringVM.DrawInfo
}
