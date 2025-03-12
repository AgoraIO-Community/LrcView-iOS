//
//  LyricLabelLineWrap.swift
//  AgoraLyricsScore
//  功能：歌词可以多行显示、逐字高亮着色
//  Created by ZYP on 2025/3/10.
//

import UIKit

public class LyricLabelLineWrap: UILabel, LysicLabelProtocol {
    /// [0, 1]
    var progressRate: CGFloat = 0 { didSet { dowkr() } }
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
    
    let iView = UIView()
    
    public var status: LysicLabelStatus = .normal { didSet { updateState() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        textAlignment = .center
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
        
        layoutIfNeeded()
    }
    
    func dowkr() {
        if text!.contains("逗留"), progressRate > 0.9 {
//            if !subviews.contains(iView) {
//                addSubview(iView)
//            }
//            iView.backgroundColor = .red
//            iView.frame = CGRect(x: 56, y: 25, width: 18, height: 25.2)
            
            print("#progressRate: \(progressRate)")
        }
        
        setNeedsDisplay()
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
    
        guard let text = text, progressRate > 0 else { return }
        
        // 新增：获取当前实际字体
        let currentFont = (status == .selectedOrHighlighted) ? textHighlightFontSize : textNormalFontSize
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineBreakStrategy = .pushOut // 新增
    
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: currentFont, // 修改此处
                .foregroundColor: textColor!,
                .paragraphStyle: paragraphStyle
            ]
        )
        
        if text.contains("逗留"), progressRate > 0.95 {
            print("")
        }
        
        // Core Text 坐标系转换
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -bounds.height)
       
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(rect: bounds, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedString.length), path, nil) // 修改此处
        
        // 获取所有行信息
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, lines.count), &lineOrigins)
        
        let highlightPath = CGMutablePath()
        let totalProgress = Swift.max(Swift.min(progressRate, 1), 0)
        
        // 新增：计算总宽度和每行比例
        var lineWidths = [CGFloat]()
        var totalWidth: CGFloat = 0
        for line in lines {
            let width = CTLineGetTypographicBounds(line, nil, nil, nil)
            lineWidths.append(CGFloat(width))
            totalWidth += CGFloat(width)
        }
        
        // 防止除零错误
        guard totalWidth > 0 else { return }
        
        var accumulatedProgress: CGFloat = 0
        for (index, line) in lines.enumerated() {
            let lineRatio = lineWidths[index] / totalWidth
            let lineStart = accumulatedProgress
            let lineEnd = accumulatedProgress + lineRatio
            
            // 获取行度量（保持原有位置计算逻辑）
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            let lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
            
            if text.contains("逗留"), progressRate > 0.9 {
                /// 读取当前 line 的文字
                let lineText = text as NSString
                let lineRange = CTLineGetStringRange(line)
                let lineTextRange = NSRange(location: lineRange.location, length: lineRange.length)
                let lineTextContent = lineText.substring(with: lineTextRange)
                print("#lineTextContent: \(lineTextContent)")
            }
            
            // 计算行位置（考虑对齐方式）
            let rawLineOrigin = lineOrigins[index]
            let lineHeight = ascent + descent
            
            // 对齐计算
            let xPosition: CGFloat = {
                switch textAlignment {
                case .left: return rawLineOrigin.x
                case .center: return (bounds.width - CGFloat(lineWidth)) / 2
                case .right: return bounds.width - CGFloat(lineWidth)
                default: return rawLineOrigin.x
                }
            }()
            
            // 转换坐标系
            let lineRect = CGRect(
                x: xPosition,
                y: rawLineOrigin.y - descent,
                width: CGFloat(lineWidth),
                height: lineHeight
            ).applying(transform)
            
            // 高亮逻辑（改用实际比例）
            if totalProgress >= lineEnd {
                highlightPath.addRect(lineRect)
            } else if totalProgress > lineStart {
                let progressInLine = (totalProgress - lineStart) / lineRatio
                let highlightWidth = lineRect.width * progressInLine
                highlightPath.addRect(CGRect(
                    x: lineRect.minX,
                    y: lineRect.minY,
                    width: highlightWidth,
                    height: lineRect.height
                ))
            }
            accumulatedProgress = lineEnd
        }
        
        // 绘制高亮部分
        if let context = UIGraphicsGetCurrentContext(), !highlightPath.isEmpty {
            context.saveGState()
            context.addPath(highlightPath)
            context.clip()
            let _textColor = textColor
            textColor = textHighlightedColor
            super.draw(rect)
            textColor = _textColor
            context.restoreGState()
        }
    }
}

