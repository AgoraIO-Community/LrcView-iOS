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
    var textHighlightedColor: UIColor = .colorWithHex(hexStr: "#FF8AB4") {
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
    /// 上下间距
    var lyricLineSpacing: CGFloat = 10 {
        didSet { updateUI() }
    }
    
    private var hasSetupUI = false
    private var leftConstraint, rightConstraint, bottomConstraint, topConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = ""
        label.status = .normal
        label.progressRate = 0
        leftConstraint.constant = 0
        label.alpha = 1
        contentView.layoutIfNeeded()
    }
    
    private func setupUI() {
        guard !hasSetupUI else {
            return
        }
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        leftConstraint = label.leftAnchor.constraint(equalTo: contentView.leftAnchor)
        rightConstraint = label.rightAnchor.constraint(greaterThanOrEqualTo: contentView.rightAnchor)
        topConstraint = label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10)
        bottomConstraint = label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        topConstraint!.isActive = true
        bottomConstraint!.isActive = true
        leftConstraint.isActive = true
        rightConstraint.isActive = true
        hasSetupUI = true
    }
    
    private func updateUI() {
        if topConstraint!.constant != lyricLineSpacing {
            topConstraint!.constant = lyricLineSpacing
            bottomConstraint!.constant = -1 * lyricLineSpacing
        }
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
        
        rollLabelIfNeed(model: model)
    }
    
    private func rollLabelIfNeed(model: Model) {
        if model.status == .normal { /** 不需要滚动 **/
            leftConstraint.constant = 0
            return
        }
        
        if model.status == .selectedOrHighlighted,
           label.bounds.width <= contentView.bounds.width { /** 不需要滚动 **/
            leftConstraint.constant = 0
            return
        }
        
        let progressRatio = model.progressRate
        /** 需要滚动label **/
        /// 当前显示文字占据该句的比率
        let displayRatio = contentView.bounds.width / label.bounds.width
        /// 开始滚动的比率位置
        let startRollingPositionRatio = displayRatio/2
        /// 结束滚动的比率位置
        let stopRollingPositionRatio = 1 - startRollingPositionRatio
        
        if progressRatio > startRollingPositionRatio, progressRatio < stopRollingPositionRatio {
            /// 计算比率差
            let deltaRatio = progressRatio - startRollingPositionRatio
            /// 计算视图的偏移距离
            let constant = deltaRatio * label.bounds.width
            /// 更新label的左边距
            leftConstraint.constant = constant * -1
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.contentView.layoutIfNeeded()
            }
        }
    }
}

extension LyricCell {
    class Model {
        let text: String
        /// 进度 0-1
        var progressRate: Double
        /// 开始时间 单位为毫秒
        let beginTime: UInt
        /// 总时长 (ms)
        let duration: UInt
        /// 状态
        var status: Status
        
        var tones: [LyricToneModel]
        
        init(text: String,
             progressRate: Double,
             beginTime: UInt,
             duration: UInt,
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
        
        var endTime: UInt {
            beginTime + duration
        }
    }
    
    typealias Status = LyricLabel.Status
}
