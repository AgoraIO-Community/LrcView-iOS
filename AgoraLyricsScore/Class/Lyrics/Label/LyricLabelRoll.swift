//
//  LyricLabelRoll.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/23.
//

import UIKit

class LyricLabelRoll: UILabel, LysicLabelProtocol {
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
    
    var status: LysicLabelStatus = .normal { didSet { updateState() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if progressRate <= 0 {
            return
        }
        let textWidth = sizeThatFits(CGSize(width: CGFloat(MAXFLOAT),
                                           height: font.lineHeight)).width
        let leftRightSpace = (bounds.width - textWidth) / 2
        let path = CGMutablePath()
        let fillRect = CGRect(x: leftRightSpace,
                              y: 0,
                              width: progressRate * textWidth,
                              height: font.lineHeight)
        path.addRect(fillRect)
        
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

