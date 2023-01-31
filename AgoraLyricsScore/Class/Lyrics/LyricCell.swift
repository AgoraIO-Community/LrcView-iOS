//
//  LyricsCell.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/23.
//

import UIKit

class LyricCell: UITableViewCell {
    private let label = LyricLabel()
    /// 正常歌词背景色
    var textNormalColor: UIColor = .gray {
        didSet { updateUI() }
    }
    /// 选中的歌词颜色
    var textSelectedColor: UIColor = .white {
        didSet { updateUI() }
    }
    /// 高亮的歌词填充颜色
    var textHighlightedColor: UIColor = .orange {
        didSet { updateUI() }
    }
    /// 正常歌词文字大小
    var textNormalFontSize: UIFont = .systemFont(ofSize: 15) {
        didSet { updateUI() }
    }
    /// 高亮歌词文字大小
    var textHighlightFontSize: UIFont = .systemFont(ofSize: 18) {
        didSet { updateUI() }
    }
    /// 最大宽度
    var maxWidth: CGFloat = UIScreen.main.bounds.width - 30 {
        didSet { updateUI() }
    }
    /// 上下间距
    var lyricLineSpacing: CGFloat = 10 {
        didSet { updateUI() }
    }
    
    private var widthConstraint: NSLayoutConstraint!
    private var hasSetupUI = false
    private var bottomConstraint, topConstraint: NSLayoutConstraint!
    
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
        label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        topConstraint = label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10)
        bottomConstraint = label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        topConstraint!.isActive = true
        bottomConstraint!.isActive = true
        hasSetupUI = true
    }
    
    private func updateUI() {
        if topConstraint!.constant != lyricLineSpacing {
            topConstraint!.constant = lyricLineSpacing
            bottomConstraint!.constant = -1 * lyricLineSpacing
        }
        label.maxWidth = maxWidth
        label.textNormalColor = textNormalColor
        label.textSelectedColor = textSelectedColor
        label.textHighlightedColor = textHighlightedColor
        label.textNormalFontSize = textNormalFontSize
        label.textHighlightFontSize = textHighlightFontSize
    }
    
    func update(model: Model) {
        label.text = model.text
        label.status = model.status
        label.progressRate = CGFloat(model.progressRate)
        Log.info(text: "update progressRate: \(model.progressRate) \(model.status)", tag: "kkkk")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = ""
        label.status = .normal
        label.progressRate = 0
    }
}

extension LyricCell {
    class Model {
        let text: String
        /// 进度 0-1
        var progressRate: Double
        /// 开始时间 单位为毫秒
        let beginTime: Int
        /// 总时长 (ms)
        let duration: Int
        /// 状态
        var status: Status
        
        var tones: [LyricToneModel]
        
        init(text: String,
             progressRate: Double,
             beginTime: Int,
             duration: Int,
             status: Status,
             tones: [LyricToneModel]) {
            self.text = text
            self.progressRate = progressRate
            self.beginTime = beginTime
            self.duration = duration
            self.status = status
            self.tones = tones
        }
        
        func update(progressRate: Double) {
            self.progressRate = progressRate
        }
        
        func update(status: Status) {
            self.status = status
        }
        
        var endTime: Int {
            beginTime + duration
        }
    }
    
    typealias Status = LyricLabel.Status
}
