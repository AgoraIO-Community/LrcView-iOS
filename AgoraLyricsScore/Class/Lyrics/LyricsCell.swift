//
//  LyricsCell.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/23.
//

import UIKit

class LyricsCell: UITableViewCell {
    private let label = LyricsLabel()
    private var uiConfig: UIConfig!
    private var widthConstraint: NSLayoutConstraint!
    private var hasSetupUI = false
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard !hasSetupUI else {
            return
        }
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        hasSetupUI = true
    }
    
    func updateUI(uiConfig: UIConfig) {
        self.uiConfig = uiConfig
        label.preferredMaxLayoutWidth = uiConfig.maxWidth
        label.setupUI(uiConfig: uiConfig.labelUIConfig)
    }
    
    func update(model: Model) {
        label.text = model.text
        label.setStatus(status: model.status)
        label.setProgressRate(progressRate: CGFloat(model.progressRate))
    }
}

extension LyricsCell {
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
        /// 最大宽度
        let maxWidth: CGFloat
        
        var labelUIConfig: LyricsLabel.UIConfig {
            LyricsLabel.UIConfig(textNormalColor: textNormalColor,
                                 textHighlightColor: textHighlightColor,
                                 textHighlightFillColor: textHighlightFillColor,
                                 textNormalFontSize: textNormalFontSize,
                                 textHighlightFontSize: textHighlightFontSize)
        }
    }
    
    class Model {
        let text: String
        /// 进度 0-1
        var progressRate: Float
        /// 开始时间 单位为毫秒
        let beginTime: Int
        /// 总时长 (ms)
        let duration: Int
        /// 状态
        var status: Status
        
        init(text: String,
             progressRate: Float,
             beginTime: Int,
             duration: Int,
             status: Status) {
            self.text = text
            self.progressRate = progressRate
            self.beginTime = beginTime
            self.duration = duration
            self.status = status
        }
        
        func update(progressRate: Float) {
            self.progressRate = progressRate
        }
        
        func update(status: Status) {
            self.status = status
        }
        
        var endTime: Int {
            beginTime + duration
        }
    }
    
    typealias Status = LyricsLabel.Status
}
