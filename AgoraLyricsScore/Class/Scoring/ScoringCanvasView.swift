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
    var standardPitchStickViewHeight: CGFloat = 10
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
    
    var minPitch: Double = 0
    var maxPitch: Double = 0
    
    fileprivate var progress: Int = 0
    fileprivate var highlightInfos = [ScoringView.Info]()
    /// 需要绘制标准pitch的数据
    fileprivate var standardInfos = [ScoringView.Info]()
    fileprivate var widthPreMs: CGFloat { movingSpeedFactor / 1000 }
    
    override func draw(_ rect: CGRect) {
        drawStaff()
        drawStandardInfos()
    }
    
    func draw(progress: Int,
              standardInfos: [ScoringView.Info],
              highlightInfos: [ScoringView.Info]) {
        self.progress = progress
        self.standardInfos = standardInfos
        self.highlightInfos = highlightInfos
        setNeedsDisplay()
    }
    
    func reset() {
        self.progress = 0
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
            UIColor.white.setFill()
            linePath.fill()
        }
    }
    
    fileprivate func drawStandardInfos() {
        drawInfos(infos: standardInfos, fillColor: standardPitchStickViewColor)
    }
    
    fileprivate func drawHitInfos() {
//        drawInfos(infos: highlightInfos, fillColor: standardPitchStickViewHighlightColor)
    }
    
    private func drawInfos(infos: [ScoringView.Info], fillColor: UIColor) {
        for info in infos {
            let beginTime = info.beginTime
            let duration = info.duration
            let pitch = info.pitch
            
            /// 视图最左边到游标这段距离对应的时长
            let defaultPitchCursorXTime = Int(defaultPitchCursorX / widthPreMs)
            let x = CGFloat(beginTime - (progress - defaultPitchCursorXTime)) * widthPreMs
            let y = getCenterY(pitch: pitch) - (standardPitchStickViewHeight / 2)
            let w = widthPreMs * CGFloat(duration)
            let h = standardPitchStickViewHeight
            let rect = CGRect(x: x, y: y, width: w, height: h)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: standardPitchStickViewHeight/2)
            fillColor.setFill()
            path.fill()
        }
    }
    
    /// 计算y的位置
    private func getCenterY(pitch: Double) -> CGFloat {
        if pitch < minPitch {
            return bounds.height
        }
        
        if pitch > maxPitch {
            return 0
        }
        /// 映射成从0开始
        let value = pitch - minPitch
        /// 计算相对偏移
        let distance = (value / (maxPitch - minPitch)) * bounds.height
        let y = bounds.height - distance
        return y
    }
}
