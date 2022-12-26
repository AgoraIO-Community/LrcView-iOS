//
//  LyricsLabel.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/23.
//

import UIKit

class LyricsLabel: UILabel {
    /// [0, 1]
    private var progressRate: CGFloat = 0
    private var uiConfig: UIConfig!
    private var status: Status = .normal
    
    /// [0, 1]
    func setProgressRate(progressRate: CGFloat) {
        self.progressRate = progressRate
        setNeedsDisplay()
    }
    
    func setupUI(uiConfig: UIConfig) {
        self.uiConfig = uiConfig
        numberOfLines = 0
    }
    
    func setStatus(status: Status) {
        self.status = status
        if status == .highlighted {
            textColor = uiConfig.textHighlightColor
            font = uiConfig.textHighlightFontSize
        }
        else {
            textColor = uiConfig.textNormalColor
            font = uiConfig.textNormalFontSize
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if progressRate <= 0 {
            return
        }
        let lines = Int(bounds.height / font.lineHeight)
        let padingTop = (bounds.height - CGFloat(lines) * font.lineHeight) / CGFloat(lines)
        let maxWidth = sizeThatFits(CGSize(width: CGFloat(MAXFLOAT),
                                           height: font.lineHeight * CGFloat(lines))).width
        let oneLineProgress = maxWidth <= bounds.width ? 1 : bounds.width / maxWidth
        let path = CGMutablePath()
        for index in 0 ..< lines {
            let leftProgress = min(progressRate, 1) - CGFloat(index) * oneLineProgress
            let fillRect: CGRect
            if leftProgress >= oneLineProgress {
                fillRect = CGRect(x: 0,
                                  y: padingTop + CGFloat(index) * font.lineHeight,
                                  width: bounds.width,
                                  height: font.lineHeight)
                path.addRect(fillRect)
            } else if leftProgress > 0 {
                if (index != lines - 1) || (maxWidth <= bounds.width) {
                    fillRect = CGRect(x: 0,
                                      y: padingTop + CGFloat(index) * font.lineHeight,
                                      width: maxWidth * leftProgress,
                                      height: font.lineHeight)
                } else {
                    let width = maxWidth.truncatingRemainder(dividingBy: bounds.width)
                    let dw = (bounds.width - width) / CGFloat(lines) + maxWidth * leftProgress
                    fillRect = CGRect(x: 0,
                                      y: padingTop + CGFloat(index) * font.lineHeight,
                                      width: dw,
                                      height: font.lineHeight)
                }
                path.addRect(fillRect)
                break
            }
        }
        if let context = UIGraphicsGetCurrentContext(), !path.isEmpty {
            context.setLineWidth(1.0)
            context.setLineCap(.butt)
            context.addPath(path)
            context.clip()
            let _textColor = textColor
            textColor = uiConfig.textHighlightFillColor
            super.draw(rect)
            textColor = _textColor
        }
    }
}

extension LyricsLabel {
    struct UIConfig {
        /// 正常歌词背景色
        let textNormalColor: UIColor
        /// 高亮的歌词颜色（未命中）
        let textHighlightColor: UIColor
        /// 高亮的歌词填充颜色 （命中）
        let textHighlightFillColor: UIColor
        /// 正常歌词文字大小
        let textNormalFontSize: UIFont
        /// 高亮歌词文字大小
        let textHighlightFontSize: UIFont
    }
    
    enum Status {
        case normal
        case highlighted
    }
}
