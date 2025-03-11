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
            textColor = textHighlightedColor
            font = textHighlightFontSize
        }
        else {
            textColor = textNormalColor
            font = textNormalFontSize
        }
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
    }
}
