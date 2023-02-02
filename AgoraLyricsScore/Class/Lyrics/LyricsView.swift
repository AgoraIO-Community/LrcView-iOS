//
//  LyricView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

protocol LyricsViewDelegate: NSObjectProtocol {
    func onLyricsViewBegainDrag(view: LyricsView)
    func onLyricsView(view: LyricsView, didDragTo position: Int)
}

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
    public var noLyricTipsText: String = "无歌词"
    /// 无歌词提示文字颜色
    public var noLyricTipsColor: UIColor = .orange
    /// 无歌词提示文字大小
    public var noLyricTipsFont: UIFont = .systemFont(ofSize: 17)
    /// 是否隐藏等待开始圆点
    public var waitingViewHidden: Bool = false { didSet { updateUI() } }
    /// 正常歌词颜色
    public var textNormalColor: UIColor = .gray
    /// 选中的歌词颜色
    public var textSelectedColor: UIColor = .white
    /// 高亮的歌词颜色 （命中）
    public var textHighlightedColor: UIColor = .colorWithHex(hexStr: "#FF8AB4")
    /// 正常歌词文字大小
    public var textNormalFontSize = UIFont(name: "PingFangSC-Semibold", size: 15)!
    /// 高亮歌词文字大小
    public var textHighlightFontSize = UIFont(name: "PingFangSC-Semibold", size: 18)!
    /// 歌词最大宽度
    public var maxWidth: CGFloat = UIScreen.main.bounds.width - 30
    /// 歌词上下间距
    public var lyricLineSpacing: CGFloat = 10
    /// 等待开始圆点风格
    public var firstToneHintViewStyle: FirstToneHintViewStyle = .init()
    /// 是否开启拖拽
    public var draggable: Bool = false
    
    var delegate: LyricsViewDelegate?
    /// 倒计时view
    fileprivate let firstToneHintView = FirstToneHintView()
    fileprivate let noLyricTipsLabel = UILabel()
    fileprivate let tableView = UITableView()
    fileprivate var lyricData: LyricModel?
    fileprivate let logTag = "LyricsView"
    fileprivate var dataList = [LyricCell.Model]()
    fileprivate var isNoLyric = false
    var progress: Int = 0 { didSet { updateProgress() } }
    /// 当前滚动到的索引
    fileprivate var currentIndex = 0
    fileprivate let referenceLineView = UIView()
    fileprivate var isDragging = false { didSet { referenceLineView.isHidden = !isDragging } }
    
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
    
    func setLyricData(data: LyricModel?) {
        currentIndex = 0
        lyricData = data
        isNoLyric = data == nil
        dataList = lyricData?.lines.map({ LyricCell.Model(text: $0.content,
                                                          progressRate: 0,
                                                          beginTime: $0.beginTime,
                                                          duration: $0.duration,
                                                          status: .normal,
                                                          tones: $0.tones) }) ?? []
        updateUI()
        tableView.reloadData()
        
        if !dataList.isEmpty, let first = dataList.first { /** 默认高亮第一个 **/
            first.update(status: .selectedOrHighlighted)
            let indexPath = IndexPath(row: currentIndex, section: 0)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            UIView.performWithoutAnimation {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    func reset() {
        firstToneHintView.reset()
        dataList = []
        progress = 0
        currentIndex = 0
        tableView.reloadData()
        Log.info(text: "reset", tag: logTag)
    }
    
    private func updateProgress() {
        guard let data = lyricData else { return }
        guard !isDragging else { return }
        Log.info(text: "updateProgress \(progress)", tag: logTag)
        let remainingTime = data.preludeEndPosition - progress
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
                    let lastIndexPath = IndexPath(row: lastIndex, section: 0)
                    
                    /// 更新当前
                    currentIndex = newCurrentIndex
                    let current = dataList[currentIndex]
                    current.update(status: .selectedOrHighlighted)
                    var progressRate: Double = 0
                    if progress > item.element.beginTime, progress <= item.element.endTime { /** 计算比例 **/
                        progressRate = calculateProgressRate(progress: progress, model: item.element)
                    }
                    current.update(progressRate: progressRate)
                    let indexPath = IndexPath(row: currentIndex, section: 0)
                    
                    UIView.performWithoutAnimation {
                        tableView.reloadRows(at: [indexPath, lastIndexPath], with: .fade)
                    }
                    tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                    Log.debug(text: "currentIndex: \(currentIndex) progressRate: \(progressRate)", tag: logTag)
                    return
                }
                
                if newCurrentIndex == currentIndex,
                   progress > item.element.beginTime,
                   progress <= item.element.endTime { /** 还在原来的句子 **/
                    
                    let current = dataList[currentIndex]
                    let progressRate: Double = calculateProgressRate(progress: progress, model: item.element)
                    current.update(progressRate: progressRate)
                    let indexPath = IndexPath(row: currentIndex, section: 0)
                    UIView.performWithoutAnimation {
                        tableView.reloadRows(at: [indexPath], with: .fade)
                    }
                    Log.debug(text: "currentIndex: \(currentIndex) progressRate: \(progressRate)", tag: logTag)
                }
            }
            else {
                Log.debug(text: "progress==: \(progress)", tag: logTag)
            }
        }
    }
    
    private func dragCellHandler(scrollView: UIScrollView) {
        let point = CGPoint(x: 0, y: scrollView.contentOffset.y + scrollView.bounds.height * 0.5)
        var indexPath = tableView.indexPathForRow(at: point)
        if indexPath == nil { /** 顶部和底部空隙 **/
            indexPath = scrollView.contentOffset.y < 0 ? IndexPath(row: 0, section: 0) : IndexPath(row: dataList.count - 1, section: 0)
        }
        let model = dataList[indexPath!.row]
        delegate?.onLyricsView(view: self, didDragTo: model.beginTime)
    }
    
    /// 计算一个句子的进度
    private func calculateProgressRate(progress: Int, model: LyricCell.Model) -> Double {
        let toneCount = model.tones.filter({ $0.word.isEmpty == false }).count
        for (index, tone) in model.tones.enumerated() {
            if progress >= tone.beginTime, progress <= tone.beginTime + tone.duration {
                let progressRate = Double((progress - tone.beginTime)) / Double(tone.duration)
                let total = (Double(index) + progressRate) / Double(toneCount)
                Log.debug(text: "total: \(total)", tag: logTag)
                return total
            }
        }
        return 0
    }
}

// MARK: - UI
extension LyricsView {
    fileprivate func setupUI() {
        backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        referenceLineView.backgroundColor = .red
        referenceLineView.isHidden = true
        addSubview(noLyricTipsLabel)
        addSubview(firstToneHintView)
        addSubview(tableView)
        addSubview(referenceLineView)
        
        noLyricTipsLabel.translatesAutoresizingMaskIntoConstraints = false
        firstToneHintView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        referenceLineView.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        referenceLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        referenceLineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        referenceLineView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        referenceLineView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true
    }
    
    fileprivate func commonInit() {
        tableView.register(LyricCell.self, forCellReuseIdentifier: "LyricsCell")
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
        firstToneHintView.isHidden = waitingViewHidden || isNoLyric
        
        if tableView.bounds.width > 0 {
            let viewFrame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height/2)
            tableView.tableHeaderView = .init(frame: viewFrame)
            tableView.tableFooterView = .init(frame: viewFrame)
        }
    }
}

// MARK: - UITableViewDataSource UITableViewDelegate
extension LyricsView: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LyricsCell", for: indexPath) as! LyricCell
        cell.textNormalColor = textNormalColor
        cell.textSelectedColor = textSelectedColor
        cell.textHighlightedColor = textHighlightedColor
        cell.textNormalFontSize = textNormalFontSize
        cell.textHighlightFontSize = textHighlightFontSize
        cell.maxWidth = maxWidth
        cell.lyricLineSpacing = lyricLineSpacing
        
        let model = dataList[indexPath.row]
        cell.update(model: model)
        return cell
    }
    
    public func scrollViewWillBeginDragging(_: UIScrollView) {
        isDragging = true
        delegate?.onLyricsViewBegainDrag(view: self)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate _: Bool) {
        if isDragging {
            dragCellHandler(scrollView: scrollView)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in /** 延时0.1秒放开，避免跳动 **/
            guard let self = self else {
                return
            }
            self.isDragging = false
        })
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isDragging {
            dragCellHandler(scrollView: scrollView)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in /** 延时0.1秒放开，避免跳动 **/
            guard let self = self else {
                return
            }
            self.isDragging = false
        })
    }
}

