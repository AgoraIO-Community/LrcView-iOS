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
        drawInfosStandrad(infos: standardInfos, fillColor: standardPitchStickViewColor)
    }
    
    fileprivate func drawHighlightInfos() {
        drawInfosStandrad(infos: highlightInfos, fillColor: standardPitchStickViewHighlightColor)
    }
    
    private func drawInfosHighlight(infos: [DrawInfo], fillColor: UIColor) {
        for info in infos {
            let rect = info.rect
            let gradient = CAGradientLayer()
            gradient.frame = rect
            gradient.colors = [UIColor.magenta.cgColor, UIColor.cyan.cgColor]

            layer.addSublayer(gradient)
        }
    }
    
    private func drawInfosStandrad(infos: [DrawInfo], fillColor: UIColor) {
        for info in infos {
            let rect = info.rect
            let path = UIBezierPath(roundedRect: rect, cornerRadius: standardPitchStickViewHeight/2)
            fillColor.setFill()
            path.fill()
        }
    }
}

extension ScoringCanvasView {
    typealias DrawInfo = ScoringVM.DrawInfo
}
