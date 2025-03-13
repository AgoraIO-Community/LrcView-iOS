//
//  LyricLabelLineWrap.swift
//  AgoraLyricsScore
//  功能：歌词可以多行显示、逐字高亮着色
//  Created by ZYP on 2025/3/10.
//

import UIKit

public class LyricLabelLineWrap: UILabel, LysicLabelProtocol {
    /// [0, 1]
    var progressRate: CGFloat = 0 { didSet { doWork() } }
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
    
    var useScrollByWord: Bool = false
    
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
            /**
             - 当需要逐字渲染的时候，设置成SelectedColor，后续在 draw 里面加一层HighlightedColor。
             -  当不需要逐字渲染，直接显示HighlightedColor
             */
            textColor = useScrollByWord ? textSelectedColor : textHighlightedColor
            font = textHighlightFontSize
        }
        else {
            textColor = textNormalColor
            font = textNormalFontSize
        }
        
        layoutIfNeeded()
    }
    
    func debug1() {
        if text!.contains("逗留"), progressRate > 0.9 {/// debug code
            if !subviews.contains(iView) {
                addSubview(iView)
            }
            iView.backgroundColor = .red
            iView.frame = CGRect(x: 56, y: 25, width: 18, height: 25.2)
            print("#progressRate: \(progressRate)")
        }
    }
    
    func debug2(text: String) {
        if text.contains("逗留"), progressRate > 0.95 {/// debug code
            let kks = getLinesWidths()
            print("")
        }
    }
    
    func debug3(line: CTLine, text: String) {
        if text.contains("泪流"), progressRate > 0.9 { /// debug code
            /// 读取当前 line 的文字
            let lineText = text as NSString
            let lineRange = CTLineGetStringRange(line)
            let lineTextRange = NSRange(location: lineRange.location, length: lineRange.length)
            let lineTextContent = lineText.substring(with: lineTextRange)
            print("#lineTextContent: \(lineTextContent)")
        }
    }
    
    func doWork() {
        debug1()
        setNeedsDisplay()
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
    
        
        guard useScrollByWord, let text = text, progressRate > 0 else { return }
        
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
                .paragraphStyle: paragraphStyle,
            ]
        )
        
        debug2(text: text)
        
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
        let lineWidths = getLinesWidths()
        let totalWidth: CGFloat = lineWidths.reduce(0, +)
        
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
            let _ = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
            let lineWidth = lineWidths[index]
            
            debug3(line: line, text: text)
            
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

import UIKit

extension UILabel {
    func getLinesWidths() -> [CGFloat] {
        guard let text = self.text else { return [] }
        
        // 合并字体设置（修复问题1）
        let currentFont = font!
        
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.font, value: currentFont, range: NSRange(location: 0, length: text.count))
        
        // 统一容器宽度设置（修复问题2）
        let containerWidth = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.width
        let textContainer = NSTextContainer(size: CGSize(
            width: containerWidth,
            height: .greatestFiniteMagnitude
        ))
        
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = numberOfLines
        
        let textStorage = NSTextStorage(attributedString: attributedString)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // 统一使用enumerateLineFragments（修复问题3）
        var lineWidths = [CGFloat]()
        layoutManager.enumerateLineFragments(forGlyphRange: NSRange(location:0, length:text.count)) {
            (rect, usedRect, _, _, _) in
            lineWidths.append(usedRect.width)
        }
        
        return lineWidths
    }
    
    func getLineMinXs() -> [CGFloat] {
        guard let text = self.text else { return [] }
        
        let currentFont = font!
        
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.font, value: currentFont, range: NSRange(location: 0, length: text.count))
        
        let containerWidth = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.width
        let textContainer = NSTextContainer(size: CGSize(
            width: containerWidth,
            height: .greatestFiniteMagnitude
        ))
        
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = numberOfLines
        
        let textStorage = NSTextStorage(attributedString: attributedString)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        var lineMinXs = [CGFloat]()
        layoutManager.enumerateLineFragments(forGlyphRange: NSRange(location:0, length:text.count)) {
            (rect, _, _, _, _) in
            // 获取每行的起始X坐标
            lineMinXs.append(rect.minX)
        }
        
        return lineMinXs
    }
}


