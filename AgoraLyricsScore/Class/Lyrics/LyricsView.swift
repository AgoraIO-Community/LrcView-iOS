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
    /// 无歌词提示文字颜色
    public var noLyricTipsColor: UIColor = .orange
    /// 无歌词提示文字大小
    public var noLyricTipsFont: UIFont = .systemFont(ofSize: 17)
    /// 是否隐藏等待开始圆点
    public var waitingViewHidden: Bool = false
    /// 提示文字大小
    public var tipsFont: UIFont = .systemFont(ofSize: 17)
    
    /// 正常歌词背景色
    public var textNormalColor: UIColor = .gray
    /// 高亮的歌词颜色（未命中）
    public var textHighlightColor: UIColor = .white
    /// 高亮的歌词填充颜色 （命中）
    public var textHighlightFillColor: UIColor = .orange
    
    /// 正常歌词文字大小
    public var textNormalFontSize: UIFont = .systemFont(ofSize: 15)
    /// 高亮歌词文字大小
    public var textHighlightFontSize: UIFont = .systemFont(ofSize: 18)
    
    /// 歌词最大宽度
    public var maxWidth: CGFloat = UIScreen.main.bounds.width - 30
    /// 歌词上下间距
    public var lyricLineSpacing: CGFloat = 10
    /// 等待开始圆点风格
    public var firstToneHintViewStyle: FirstToneHintViewStyle = .init()
    /// 是否开启拖拽
    public var draggable: Bool = false
    
    /// 倒计时view
    fileprivate let firstToneHintView = FirstToneHintView()
    fileprivate let noLyricTipsLabel = UILabel()
    fileprivate let tableView = UITableView()
    fileprivate var lyricData: LyricModel!
    fileprivate let logTag = "LyricsView"
    fileprivate var dataList = [LyricsCell.Model]()
    fileprivate var isNoLyric = false
    fileprivate var progress: Int = 0
    /// 当前滚动到的索引
    fileprivate var currentIndex = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    func setLyricData(data: LyricModel) {
        currentIndex = 0
        lyricData = data
        isNoLyric = data.isEmpty
        dataList = lyricData.lines.map({ LyricsCell.Model(text: $0.content,
                                                          progressRate: 0,
                                                          beginTime: $0.beginTime,
                                                          duration: $0.duration,
                                                          status: .normal) })
        updateUI()
        tableView.reloadData()
        
        if !dataList.isEmpty, let first = dataList.first { /** 默认高亮第一个 **/
            first.update(status: .highlighted)
            let indexPath = IndexPath(row: currentIndex, section: 0)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            let cell = tableView.cellForRow(at: indexPath) as! LyricsCell
            cell.update(model: first)
        }
    }
    
    func setProgress(progress: Int) {
        self.progress = progress
        updateProgress()
    }
    
    private func updateProgress() {
        let remainingTime = lyricData.preludeEndPosition - progress
        firstToneHintView.setRemainingTime(time: remainingTime)
        
        if !dataList.isEmpty, currentIndex < dataList.count {
            if let item = dataList.enumerated().first (where: { progress < $0.element.endTime }) { /** 找出第一个要高亮的 **/
                let newCurrentIndex = item.offset
                
                if newCurrentIndex != currentIndex { /** 切换了新的 **/
                    /// 恢复上一个
                    let lastIndex = currentIndex
                    let last = dataList[lastIndex]
                    last.update(status: .normal)
                    last.update(progressRate: 0)
                    Log.debug(text: "currentIndex: \(currentIndex) progressRate: 0", tag: logTag)
                    let lastIndexPath = IndexPath(row: lastIndex, section: 0)
                    let lastCell = tableView.cellForRow(at: lastIndexPath) as! LyricsCell
                    lastCell.update(model: last)
                    
                    /// 更新当前
                    currentIndex = newCurrentIndex
                    let current = dataList[currentIndex]
                    current.update(status: .highlighted)
                    var progressRate: Float = 0
                    if progress > item.element.beginTime, progress <= item.element.endTime { /** 计算比例 **/
                        progressRate = Float((progress - item.element.beginTime) / item.element.duration)
                    }
                    current.update(progressRate: progressRate)
                    let indexPath = IndexPath(row: currentIndex, section: 0)
                    let cell = tableView.cellForRow(at: indexPath) as! LyricsCell
                    cell.update(model: current)
                    tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                    Log.debug(text: "currentIndex: \(currentIndex) progressRate: \(progressRate)", tag: logTag)
                    return
                }
                
                if newCurrentIndex == currentIndex,
                    progress > item.element.beginTime,
                    progress <= item.element.endTime { /** 还在原来的句子 **/
                    
                    let current = dataList[currentIndex]
                    let progressRate: Float = Float(progress - item.element.beginTime) / Float(item.element.duration)
                    current.update(progressRate: progressRate)
                    let indexPath = IndexPath(row: currentIndex, section: 0)
                    let cell = tableView.cellForRow(at: indexPath) as! LyricsCell
                    cell.update(model: current)
                    Log.debug(text: "currentIndex: \(currentIndex) progressRate: \(progressRate)", tag: logTag)
                }
            }
            else {
                Log.debug(text: "progress==: \(progress)", tag: logTag)
            }
            
        }
        
    }
}

extension LyricsView { /** UI **/
    fileprivate func setupUI() {
        backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        addSubview(noLyricTipsLabel)
        addSubview(firstToneHintView)
        addSubview(tableView)
        
        noLyricTipsLabel.translatesAutoresizingMaskIntoConstraints = false
        firstToneHintView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        noLyricTipsLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        noLyricTipsLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        firstToneHintView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        firstToneHintView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        firstToneHintView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        firstToneHintView.heightAnchor.constraint(equalToConstant: firstToneHintViewStyle.size).isActive = true
        
        let constant = firstToneHintViewStyle.size + firstToneHintViewStyle.bottomMargin
        tableView.topAnchor.constraint(equalTo: topAnchor, constant: constant).isActive = true
        tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    fileprivate func commonInit() {
        tableView.register(LyricsCell.self, forCellReuseIdentifier: "LyricsCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    fileprivate func updateUI() {
        noLyricTipsLabel.textColor = noLyricTipsColor
        noLyricTipsLabel.text = noLyricTipsText
        noLyricTipsLabel.font = noLyricTipsFont
        noLyricTipsLabel.isHidden = !isNoLyric
        tableView.isHidden = isNoLyric
        tableView.isScrollEnabled = draggable
    }
}

extension LyricsView: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LyricsCell", for: indexPath) as! LyricsCell
        let config = LyricsCell.UIConfig(textNormalColor: textNormalColor,
                                         textHighlightColor: textHighlightColor,
                                         textHighlightFillColor: textHighlightFillColor,
                                         textNormalFontSize: textNormalFontSize,
                                         textHighlightFontSize: textHighlightFontSize,
                                         maxWidth: maxWidth)
        cell.updateUI(uiConfig: config)
        let model = dataList[indexPath.row]
        cell.update(model: model)
        return cell
    }

    public func scrollViewWillBeginDragging(_: UIScrollView) {
        
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate _: Bool) {
        
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
}

