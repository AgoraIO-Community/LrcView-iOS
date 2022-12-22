//
//  LyricView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class FirstToneHintViewStyle: NSObject {
    /// 背景色
    public var backgroundColor: UIColor? = .gray
    /// 大小
    public var size: CGFloat = 10
    /// 底部间距
    public var bottomMargin: CGFloat = 0
}

public class LyricsView: UIView {
    /// 无歌词提示文案
    public var noLyricTipsText: String = "纯音乐，无歌词"
    /// 纯音乐 提示文字颜色
    public var noLyricTipsColor: UIColor = .orange
    /// 是否隐藏等待开始圆点
    public var waitingViewHidden: Bool = false
    /// 提示文字大小
    public var tipsFont: UIFont = .systemFont(ofSize: 17)
    /// 默认歌词背景色
    public var defaultBackgroundColor: UIColor = .gray
    /// 高亮歌词背景色
    public var highlightedBackgroundColor: UIColor = .white
    /// 正常的歌词颜色
    public var textNormalColor: UIColor = .white
    /// 实时绘制的歌词颜色
    public var textHighlightColor: UIColor = .orange
    /// 歌词文字大小
    public var textNormalFontSize: UIFont = .systemFont(ofSize: 15)
    /// 歌词高亮文字大小
    public var textHighlightFontSize: UIFont = .systemFont(ofSize: 18)
    /// 歌词最大宽度
    public var maxWidth: CGFloat = UIScreen.main.bounds.width - 30
    /// 歌词上下间距
    public var lyricLineSpacing: CGFloat = 10
    /// 等待开始圆点风格
    public var firstToneHintViewStyle: FirstToneHintViewStyle = .init()
    /// 是否开启拖拽
    public var draggable: Bool = true
    
    /// 倒计时view
    fileprivate let firstToneHintView = FirstToneHintView()
    fileprivate let firstToneHintViewHeight: CGFloat = 25
    fileprivate let tableView = UITableView()
    fileprivate var lyricData: LyricModel!
    fileprivate let logTag = "LyricsView"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setLyricData(data: LyricModel) {
        lyricData = data
    }
    
    public func setProgress(progress: Int) {
        let remainingTime = lyricData.preludeEndPosition - progress
        firstToneHintView.setrRemainingTime(time: remainingTime)
    }
    
}

extension LyricsView { /** UI **/
    fileprivate func setupUI() {
        addSubview(firstToneHintView)
//        addSubview(tableView)
        
        firstToneHintView.translatesAutoresizingMaskIntoConstraints = false
//        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        firstToneHintView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        firstToneHintView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        firstToneHintView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        firstToneHintView.heightAnchor.constraint(equalToConstant: firstToneHintViewHeight).isActive = true
        
//        tableView.topAnchor.constraint(equalTo: topAnchor, constant: firstToneHintViewHeight + firstToneHintViewStyle.bottomMargin).isActive = true
//        tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
//        tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
//        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    fileprivate func commonInit() {}
}

