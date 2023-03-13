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

public class LyricsView: UIView {
    /// 无歌词提示文案
    @objc public var noLyricTipsText: String = "无歌词" { didSet { updateUI() } }
    /// 无歌词提示文字颜色
    @objc public var noLyricTipsColor: UIColor = .orange { didSet { updateUI() } }
    /// 无歌词提示文字大小
    @objc public var noLyricTipsFont: UIFont = .systemFont(ofSize: 17) { didSet { updateUI() } }
    /// 是否隐藏等待开始圆点
    @objc public var waitingViewHidden: Bool = false { didSet { updateUI() } }
    /// 正常歌词颜色
    @objc public var textNormalColor: UIColor = .white
    /// 选中的歌词颜色
    @objc public var textSelectedColor: UIColor = .white
    /// 高亮的歌词颜色 （命中）
    @objc public var textHighlightedColor: UIColor = .colorWithHex(hexStr: "#FF8AB4")
    /// 正常歌词文字大小
    @objc public var textNormalFontSize = UIFont(name: "PingFangSC-Semibold", size: 15)!
    /// 高亮歌词文字大小
    @objc public var textHighlightFontSize = UIFont(name: "PingFangSC-Semibold", size: 18)!
    /// 歌词最大宽度
    @objc public var maxWidth: CGFloat = UIScreen.main.bounds.width - 30
    /// 歌词上下间距
    @objc public var lyricLineSpacing: CGFloat = 10
    /// 等待开始圆点风格
    @objc public let firstToneHintViewStyle: FirstToneHintViewStyle = .init()
    /// 是否开启拖拽
    @objc public var draggable: Bool = false
    /// use for debug only
    @objc public var showDebugView = false { didSet { updateUI() } }
    
    weak var delegate: LyricsViewDelegate?
    /// 倒计时view
    fileprivate let firstToneHintView = FirstToneHintView()
    fileprivate let consoleView = ConsoleView()
    fileprivate let noLyricTipsLabel = UILabel()
    fileprivate let tableView = UITableView()
    fileprivate let logTag = "LyricsView"
    fileprivate var dataList = [LyricCell.Model]()
    fileprivate var isNoLyric = false
    fileprivate let referenceLineView = UIView()
    fileprivate var isDragging = false { didSet { referenceLineView.isHidden = !isDragging } }
    fileprivate var tableViewTopConstraint: NSLayoutConstraint!, firstToneHintViewHeightConstraint: NSLayoutConstraint!
    fileprivate let lyricMachine = LyricMachine()
    
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
        isNoLyric = data == nil
        updateUI()
        lyricMachine.setLyricData(data: data)
    }
    
    func reset() {
        lyricMachine.reset()
        tableView.isScrollEnabled = false
        firstToneHintView.reset()
        dataList = []
        tableView.reloadData()
        Log.info(text: "reset", tag: logTag)
    }
    
    func setProgress(progress: Int) {
        guard !isDragging else { return }
        lyricMachine.setProgress(progress: progress)
    }
    
    private func dragCellHandler(scrollView: UIScrollView) {
        guard !dataList.isEmpty else {
            Log.error(error: "dragCellHandler dataList isEmpty", tag: logTag)
            return
        }
        let point = CGPoint(x: 0, y: scrollView.contentOffset.y + scrollView.bounds.height * 0.5)
        var indexPath = tableView.indexPathForRow(at: point)
        if indexPath == nil { /** 顶部和底部空隙 **/
            indexPath = scrollView.contentOffset.y < 0 ? IndexPath(row: 0, section: 0) : IndexPath(row: dataList.count - 1, section: 0)
        }
        let model = dataList[indexPath!.row]
        delegate?.onLyricsView(view: self, didDragTo: model.beginTime)
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
        firstToneHintView.style = firstToneHintViewStyle
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
        
        let topSpace: CGFloat = 5
        firstToneHintView.topAnchor.constraint(equalTo: topAnchor, constant: topSpace).isActive = true
        firstToneHintView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        firstToneHintView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        firstToneHintViewHeightConstraint = firstToneHintView.heightAnchor.constraint(equalToConstant: firstToneHintViewStyle.size)
        firstToneHintViewHeightConstraint.isActive = true
        
        let constant = firstToneHintViewStyle.size + firstToneHintViewStyle.bottomMargin + topSpace
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: topAnchor, constant: constant)
        tableViewTopConstraint.isActive = true
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
        firstToneHintViewStyle.didUpdate = { [weak self] in
            guard let self = self else { return }
            self.updateUI()
        }
        lyricMachine.delegate = self
    }
    
    fileprivate func updateUI() {
        noLyricTipsLabel.textColor = noLyricTipsColor
        noLyricTipsLabel.text = noLyricTipsText
        noLyricTipsLabel.font = noLyricTipsFont
        noLyricTipsLabel.isHidden = !isNoLyric
        tableView.isHidden = isNoLyric
        tableView.isScrollEnabled = draggable
        firstToneHintView.isHidden = isNoLyric ? true : waitingViewHidden
        firstToneHintView.style = firstToneHintViewStyle
        let constant = firstToneHintViewStyle.size + firstToneHintViewStyle.bottomMargin
        tableViewTopConstraint.constant = constant
        firstToneHintViewHeightConstraint.constant = firstToneHintViewStyle.size
        
        if tableView.bounds.width > 0 {
            let viewFrame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height/2)
            tableView.tableHeaderView = .init(frame: viewFrame)
            tableView.tableFooterView = .init(frame: viewFrame)
        }
        
        if showDebugView {
            if !subviews.contains(consoleView) {
                addSubview(consoleView)
                consoleView.translatesAutoresizingMaskIntoConstraints = false
                consoleView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
                consoleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                consoleView.widthAnchor.constraint(equalToConstant: 80).isActive = true
                consoleView.heightAnchor.constraint(equalToConstant: 80).isActive = true
            }
        }
        else {
            consoleView.removeFromSuperview()
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
            lyricMachine.setDragEnd()
            isDragging = false
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isDragging {
            dragCellHandler(scrollView: scrollView)
            lyricMachine.setDragEnd()
            isDragging = false
        }
    }
}

// MARK: - LyricMachineDelegate
extension LyricsView: LyricMachineDelegate {
    func lyricMachine(_ lyricMachine: LyricMachine, didSetLyricData datas: [LyricCell.Model]) {
        dataList = datas
        tableView.reloadData()
        
        if !datas.isEmpty { /** 默认高亮第一个 **/
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            UIView.performWithoutAnimation {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    func lyricMachine(_ lyricMachine: LyricMachine, didUpdate remainingTime: Int) {
        firstToneHintView.setRemainingTime(time: remainingTime)
    }
    
    func lyricMachine(_ lyricMachine: LyricMachine,
                      didStartLineAt newIndexPath: IndexPath,
                      oldIndexPath: IndexPath,
                      animated: Bool) {
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: [newIndexPath, oldIndexPath], with: .fade)
        }
        tableView.scrollToRow(at: newIndexPath, at: .middle, animated: animated)
    }
    
    func lyricMachine(_ lyricMachine: LyricMachine, didUpdateLineAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? LyricCell{
            let model = dataList[indexPath.row]
            cell.update(model: model)
        }
    }
    
    func lyricMachine(_ lyricMachine: LyricMachine, didUpdateConsloe text: String) {
        consoleView.set(text: text)
    }
}
