//
//  LyricLabelLineWrap.swift
//  AgoraLyricsScore
//  功能：歌词可以多行显示、逐字高亮着色
//  Created by ZYP on 2025/3/10.
//

import UIKit

public class LyricLabelLineWrap: UILabel, LysicLabelProtocol {
    /// [0, 1]
    var progressRate: CGFloat = 0
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
    
    public var status: LysicLabelStatus = .normal { didSet { updateState() } }
    
    
    private var currentWordItems: [ToneProgressItem] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        textAlignment = .left
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
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard !currentWordItems.isEmpty else {
            super.draw(rect)
            return
        }
        
        
        // 逐字绘制高亮部分
        let path = CGMutablePath()
        for (index, wordItem) in currentWordItems.enumerated() {
            if wordItem.progressRate > 0 {
                if let rect = rectForCharacter(at: index) {
                    let progressWidth = rect.width * CGFloat(wordItem.progressRate)
                    let clipRect = CGRect(x: rect.minX,
                                          y: rect.minY,
                                          width: progressWidth,
                                          height: rect.height)
                    path.addRect(clipRect)
                }
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
    
    private func colorForWordItem(_ item: ToneProgressItem) -> UIColor {
        // 删除原有颜色判断，颜色绘制逻辑现在在draw方法中处理
        return .clear // 此处颜色不再使用
    }
    
    /// 每次更新歌词进度时候调用
    func update(wordItems: [ToneProgressItem]) {
        currentWordItems = wordItems
        setNeedsDisplay()
    }
}


import CoreText

extension UILabel {
    func rectForCharacter(at index: Int) -> CGRect? {
        guard let text = self.text, index < text.count else { return nil }
        
        // Core Text 坐标系转换
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -bounds.height)
        let attributedString = NSAttributedString(
            string: text,
            attributes: [.font: font!, .foregroundColor: textColor!]
        )
        
        // 创建 framesetter
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(rect: bounds, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        // 遍历 CTLine 查找目标字符
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var lineOrigin = CGPoint.zero
        var currentIndex = 0
        
        for (lineIndex, line) in lines.enumerated() {
            CTFrameGetLineOrigins(frame, CFRangeMake(lineIndex, 1), &lineOrigin)
            let lineRange = CTLineGetStringRange(line)
            
            if currentIndex + lineRange.length > index {
                // 找到目标字符在行中的位置
                let xOffset = CTLineGetOffsetForStringIndex(line, index, nil)
                var width = CGFloat(CTLineGetOffsetForStringIndex(line, index + 1, nil) - xOffset)
                
                // 获取字形度量
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
                
                // 计算实际位置（考虑对齐方式）
                let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
                let xPosition = calculateXPosition(lineWidth: lineWidth,
                                                  xOffset: xOffset,
                                                  lineOrigin: lineOrigin)
                
                if width.isNaN {
                    // 处理换行导致的空白情况
                    width = 0
                }
                
                let rect = CGRect(
                    x: xPosition,
                    y: lineOrigin.y - descent,
                    width: width,
                    height: ascent + descent
                ).applying(transform)
                
                return rect.offsetBy(dx: 0, dy: 0)
            }
            
            currentIndex += lineRange.length
        }
        
        return nil
    }
    
    
    private func calculateXPosition(lineWidth: Double, xOffset: CGFloat, lineOrigin: CGPoint) -> CGFloat {
        switch textAlignment {
        case .left:
            return lineOrigin.x + xOffset
        case .center:
            return (bounds.width - CGFloat(lineWidth)) / 2 + xOffset
        case .right:
            return bounds.width - CGFloat(lineWidth) + xOffset
        default:
            return lineOrigin.x + xOffset
        }
    }
}
