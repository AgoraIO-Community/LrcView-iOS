//
//  LyricCellLineWrap.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2025/3/10.
//

import UIKit

class LyricCellLineWrap: UITableViewCell, LyricCellProtocol {
    static let idf = "LyricCellLineWrap"
    
    private let label = LyricLabelLineWrap()
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = ""
        label.status = .normal
        label.progressRate = 0
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
        
        label.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        label.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
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
        label.textNormalColor = textNormalColor
        label.textSelectedColor = textSelectedColor
        label.textHighlightedColor = textHighlightedColor
        label.textNormalFontSize = textNormalFontSize
        label.textHighlightFontSize = textHighlightFontSize
    }
    
    func update(model: LyricCellModel) {
        label.text = model.text
        label.status = model.status
        label.progressRate = model.progressRate
    }
}

