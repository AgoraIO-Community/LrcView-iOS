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
    let debug = false
    
    public var status: LysicLabelStatus = .normal { didSet { updateState() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        textAlignment = .center
        sizeToFit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        preferredMaxLayoutWidth = bounds.width
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
        guard debug else {
            return
        }
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
        guard debug else {
            return
        }
        if text.contains("逗留"), progressRate > 0.95 {/// debug code
            
            print("")
        }
    }
    
    func debug3(line: CTLine, text: String) {
        guard debug else {
            return
        }
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
        
        
        guard useScrollByWord, let _ = text, progressRate > 0, let context = UIGraphicsGetCurrentContext() else { return }
        
        let highlightPath = CGMutablePath()
        let totalProgress = Swift.max(Swift.min(progressRate, 1), 0)
        
        let lineRects = getLinesRects(thefont: textHighlightFontSize)
        let lineWidths = lineRects.map({ $0.width})
        let totalWidth: CGFloat = lineWidths.reduce(0, +)
        
        /// work around
        let widthExtend: CGFloat = 10
        
        // 防止除零错误
        guard totalWidth > 0 else { return }
        var accumulatedProgress: CGFloat = 0
        for (_, rect) in lineRects.enumerated() {
            let lineRatio = rect.width / totalWidth
            let lineStart = accumulatedProgress
            let lineEnd = accumulatedProgress + lineRatio
            
            // 对齐计算
            let xPosition: CGFloat = {
                switch textAlignment {
                case .left: return 0
                case .center: return (bounds.width - 0 - CGFloat(rect.width)) / 2 - widthExtend/2
                case .right: return bounds.width - 0 - CGFloat(rect.width) - widthExtend/2
                default: return 0
                }
            }()
            // 转换坐标系
            let lineRect = CGRect(
                x: xPosition,
                y: rect.minY,
                width: rect.width + widthExtend,
                height: rect.height
            )
            
            // 高亮逻辑
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
        if !highlightPath.isEmpty {
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

extension UILabel {
    func getLinesRects(thefont: UIFont) -> [CGRect] {
        guard let text = self.text else { return [] }
        
        
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.font, value: thefont, range: NSRange(location: 0, length: text.count))
        
        let containerWidth = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.width
        let textContainer = NSTextContainer(size: CGSize(
            width: containerWidth,
            height: .greatestFiniteMagnitude
        ))
        
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = numberOfLines
//        textContainer.lineFragmentPadding = 3
        let textStorage = NSTextStorage(attributedString: attributedString)
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // 统一使用enumerateLineFragments（修复问题3）
        var lineRects = [CGRect]()
        layoutManager.enumerateLineFragments(forGlyphRange: NSRange(location:0, length:text.count)) {
            (rect, usedRect, _, _, _) in
            lineRects.append(usedRect)
        }
        
        return lineRects
    }
}


