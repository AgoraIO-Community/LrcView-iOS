//
//  LyricsLabel.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/23.
//

import UIKit

class LyricLabel: UILabel {
    /// [0, 1]
    var progressRate: CGFloat = 0 { didSet { setNeedsDisplay() } }
    /// 正常歌词颜色
    var textNormalColor: UIColor = .gray
    /// 选中的歌词颜色
    var textSelectedColor: UIColor = .white
    /// 高亮的歌词颜色
    var textHighlightedColor: UIColor = .orange
    /// 正常歌词文字大小
    var textNormalFontSize: UIFont = .systemFont(ofSize: 15)
    /// 高亮歌词文字大小
    var textHighlightFontSize: UIFont = .systemFont(ofSize: 18)
    var maxWidth: CGFloat = 0
    
    var status: Status = .normal { didSet { updateState() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        numberOfLines = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateState() {
        if status == .selectedOrHighlighted {
            textColor = textSelectedColor
            font = textHighlightFontSize
        }
        else {
            textColor = textNormalColor
            font = textNormalFontSize
        }
        preferredMaxLayoutWidth = maxWidth
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
            textColor = textHighlightedColor
            super.draw(rect)
            textColor = _textColor
        }
    }
}

extension LyricLabel {
    enum Status {
        case normal
        case selectedOrHighlighted
    }
}
