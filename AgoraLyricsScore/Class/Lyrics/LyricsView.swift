//
//  LyricView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

protocol LyricsViewDelegate: NSObjectProtocol {
    func onLyricsViewBegainDrag(view: LyricsView)
    func onLyricsView(view: LyricsView, didDragTo position: UInt)
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
    /// 非活跃歌词颜色（未唱、已唱）
    @objc public var inactiveLineTextColor: UIColor = .white
    /// 活跃的歌词颜色 （即将唱）
    @objc public var activeLineUpcomingTextColor: UIColor = .white
    /// 活跃的歌词颜色 （正在唱）
    @objc public var activeLinePlayedTextColor: UIColor = .colorWithHex(hexStr: "#FF8AB4")
    /// 非活跃歌词文字大小（未唱、已唱）
    @objc public var inactiveLineFontSize = UIFont(name: "PingFangSC-Semibold", size: 15)!
    /// 活跃歌词文字大小 （即将唱、正在唱）
    @objc public var activeLineUpcomingFontSize = UIFont(name: "PingFangSC-Semibold", size: 18)!
    /// 歌词上下间距
    @objc public var lyricLineSpacing: CGFloat = 10
    /// 等待开始圆点风格
    @objc public let firstToneHintViewStyle: FirstToneHintViewStyle = .init()
    /// 是否开启拖拽
    @objc public var draggable: Bool = false
    /// 活跃的歌词的位置
    @objc public var activeLinePosition: UITableView.ScrollPosition = .middle
    /// 是否使用换行风格 （以歌曲为单位，不支持中途修改）
    @objc public var enableLineWrap = false
    /// use for debug only
    @objc public var showDebugView = false { didSet { updateUI() } }
    
    weak var delegate: LyricsViewDelegate?
    /// 倒计时view
    fileprivate let firstToneHintView = FirstToneHintView()
    fileprivate let consoleView = ConsoleView()
    fileprivate let noLyricTipsLabel = UILabel()
    fileprivate let tableView = UITableView()
    fileprivate let logTag = "LyricsView"
    fileprivate var dataList = [LyricCellModel]()
    fileprivate var isNoLyric = false
    fileprivate let referenceLineView = UIView()
    fileprivate var isDragging = false { didSet { referenceLineView.isHidden = !isDragging } }
    fileprivate var tableViewTopConstraint: NSLayoutConstraint!, firstToneHintViewHeightConstraint: NSLayoutConstraint!
    fileprivate let lyricMachine = LyricMachine()
    fileprivate var lyricsDataCanScrollByWord = false
    fileprivate var useLineWrap = false
    
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
        lyricsDataCanScrollByWord = data?.lyricsType ?? .lrc != .lrc
        /// 判断是否用换行显示
        Log.debug(text: "enableLineWrap = \(enableLineWrap),lyricsDataCanScrollByWord = \(lyricsDataCanScrollByWord) ", tag: logTag)
        
        if enableLineWrap {
            useLineWrap = true
        }
        else {
            if lyricsDataCanScrollByWord {
                useLineWrap = false
            }
            else {
                useLineWrap = true
            }
        }
        
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
    
    func setProgress(progress: UInt) {
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
            if scrollView.contentOffset.y < 0 {
                indexPath = IndexPath(row: 0, section: 0)
            }
            else {
                Log.debug(text: "selecte last at \(point.y)", tag: logTag)
                indexPath = IndexPath(row: dataList.count - 1, section: 0)
            }
        }
        Log.debug(text:"dragCellHandler \(indexPath!.row) \(point.y) = \(scrollView.contentOffset.y) + \(scrollView.bounds.height * 0.5)", tag: logTag)
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
        tableView.estimatedRowHeight = 35
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(LyricCellRoll.self, forCellReuseIdentifier: LyricCellRoll.idf)
        tableView.register(LyricCellLineWrap.self, forCellReuseIdentifier: LyricCellLineWrap.idf)
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
            Log.debug(text: "viewFrame:\(viewFrame.height)", tag: logTag)
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
        let idf = useLineWrap ? LyricCellLineWrap.idf : LyricCellRoll.idf
        let cell = tableView.dequeueReusableCell(withIdentifier: idf, for: indexPath) as! LyricCellProtocol
        cell.textNormalColor = inactiveLineTextColor
        cell.textSelectedColor = activeLineUpcomingTextColor
        cell.textHighlightedColor = activeLinePlayedTextColor
        cell.textNormalFontSize = inactiveLineFontSize
        cell.textHighlightFontSize = activeLineUpcomingFontSize
        cell.lyricLineSpacing = lyricLineSpacing
        
        let model = dataList[indexPath.row]
        cell.update(model: model)
        return cell
    }
    
    public func scrollViewWillBeginDragging(_: UIScrollView) {
        Log.info(text: "scrollViewWillBeginDragging", tag: logTag)
        isDragging = true
        delegate?.onLyricsViewBegainDrag(view: self)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        Log.info(text: "scrollViewDidEndDragging decelerate \(decelerate)", tag: logTag)
        if isDragging {
            dragCellHandler(scrollView: scrollView)
            lyricMachine.setDragEnd()
            isDragging = false
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        Log.info(text: "scrollViewDidEndDecelerating", tag: logTag)
        if isDragging {
            dragCellHandler(scrollView: scrollView)
            lyricMachine.setDragEnd()
            isDragging = false
        }
    }
}

// MARK: - LyricMachineDelegate
extension LyricsView: LyricMachineDelegate {
    func lyricMachine(_ lyricMachine: LyricMachine, didSetLyricData datas: [LyricCellModel]) {
        Log.debug(text: "set dataList \(datas.count)", tag: logTag)
        dataList = datas
        tableView.reloadData()
        
        if !datas.isEmpty { /** 默认高亮第一个 **/
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: activeLinePosition, animated: true)
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
        guard !dataList.isEmpty else {
            Log.debug(text: "update tableView will be ignore because dataList is empty", tag: logTag)
            return
        }
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: [newIndexPath, oldIndexPath], with: .fade)
        }
        tableView.scrollToRow(at: newIndexPath, at: activeLinePosition, animated: animated)
    }
    
    func lyricMachine(_ lyricMachine: LyricMachine, didUpdateLineAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? LyricCellProtocol {
            let model = dataList[indexPath.row]
            cell.update(model: model)
        }
    }
    
    func lyricMachine(_ lyricMachine: LyricMachine, didUpdateConsloe text: String) {
        consoleView.set(text: text)
    }
}
