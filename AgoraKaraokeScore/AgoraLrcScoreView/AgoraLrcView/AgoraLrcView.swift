//
//  AgoraLrcView.swift
//  AgoraKaraokeScore
//
//  Created by zhaoyongqiang on 2021/12/10.
//

import UIKit

class AgoraLrcView: UIView {
    /// 滚动歌词后设置播放器时间
    var seekToTime: ((TimeInterval) -> Void)?
    /// 当前播放的歌词
    var currentPlayerLrc: ((String, CGFloat) -> Void)?
    /// 当前歌词pitch回调
    var currentWordPitchClosure: ((Int, Int) -> Void)?
    /// 当前行结束回调
    var currentLineEndsClosure: (() -> Void)?

    private var _lrcConfig: AgoraLrcConfigModel = .init() {
        didSet {
            updateUI()
        }
    }

    var lrcConfig: AgoraLrcConfigModel? {
        set {
            _lrcConfig = newValue ?? AgoraLrcConfigModel()
        }
        get {
            return _lrcConfig
        }
    }

    var miguSongModel: AgoraMiguSongLyric? {
        didSet {
            guard miguSongModel != nil else { return }
            dataArray = miguSongModel?.sentences
            // 计算总pitch数量
            totalPitchCount = miguSongModel?.sentences
                .flatMap { $0.tones }.filter { $0.pitch > 0 }.count ?? 0
        }
    }

    var lrcDatas: [AgoraLrcModel]? {
        didSet {
            dataArray = lrcDatas
            guard let data = lrcDatas, !data.isEmpty else { return }
            _lrcConfig.lrcHighlightColor = .clear
        }
    }

    private var dataArray: [Any]? {
        didSet {
            tipsLabel.isHidden = !(dataArray?.isEmpty ?? true)
            tableView.reloadData()
        }
    }

    private var progress: CGFloat = 0 {
        didSet {
            let cell = tableView.cellForRow(at: IndexPath(row: scrollRow, section: 0)) as? AgoraMusicLrcCell
            cell?.setupMusicLrcProgress(with: progress)
        }
    }

    /// 当前歌词所在的位置
    private var preRow: Int = -1
    private var scrollRow: Int = -1 {
        didSet {
            if scrollRow == oldValue || scrollRow < 0 { return }
            if preRow > -1 && (dataArray?.count ?? 0) > 0 {
                UIView.performWithoutAnimation {
                    tableView.reloadRows(at: [IndexPath(row: preRow, section: 0)], with: .fade)
                }
            }
            let indexPath = IndexPath(row: scrollRow, section: 0)
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.scrollToRow(at: indexPath, at: _lrcConfig.lyricsScrollPosition, animated: true)
            preRow = scrollRow
        }
    }

    private lazy var statckView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    private lazy var loadView: AgoraLoadingView = {
        let view = AgoraLoadingView()
        view.delegate = self
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.scrollsToTop = false
        tableView.estimatedRowHeight = 30
        tableView.rowHeight = UITableView.automaticDimension
        tableView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        tableView.register(AgoraMusicLrcCell.self, forCellReuseIdentifier: "AgoaraLrcViewCell")
        return tableView
    }()

    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor(white: 0, alpha: 0.05).cgColor,
                                UIColor(white: 0, alpha: 0.8).cgColor]
        gradientLayer.locations = [0.7, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        return gradientLayer
    }()

    /** 提示 */
    private lazy var tipsLabel: UILabel = {
        let view = UILabel()
        view.textColor = .blue
        view.text = "纯音乐，无歌词"
        view.font = .systemFont(ofSize: 17)
        view.isHidden = true
        return view
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .darkGray
        view.isHidden = true
        return view
    }()

    private var isDragging: Bool = false {
        didSet {
            lineView.isHidden = _lrcConfig.isHiddenSeparator || !isDragging
        }
    }

    private var currentTime: TimeInterval = 0
    private var totalPitchCount: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let margin = statckView.frame.height * 0.5
        tableView.contentInset = UIEdgeInsets(top: 0,
                                              left: 0,
                                              bottom: margin,
                                              right: 0)

        gradientLayer.frame = CGRect(x: 0,
                                     y: 0,
                                     width: bounds.width,
                                     height: _lrcConfig.bottomMaskHeight > 0 ? _lrcConfig.bottomMaskHeight : bounds.height)
        tableView.superview?.layer.addSublayer(gradientLayer)
        if tableView.backgroundColor != .clear {
            tableView.backgroundColor = .clear
            tableView.separatorStyle = .none
        }
    }

    private func setupUI() {
        backgroundColor = .clear
        statckView.translatesAutoresizingMaskIntoConstraints = false
        loadView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tipsLabel.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statckView)
        statckView.addArrangedSubview(loadView)
        statckView.addArrangedSubview(tableView)
        tableView.addSubview(tipsLabel)
        addSubview(lineView)

        statckView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        statckView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        statckView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        statckView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        tipsLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        tipsLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true

        lineView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor).isActive = true
        lineView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        lineView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true

        updateUI()

        layoutIfNeeded()
    }

    private var preTime: TimeInterval = 0
    func start(currentTime: TimeInterval) {
        guard !(dataArray?.isEmpty ?? false) else { return }
        let time: TimeInterval = lrcDatas == nil ? 1000 : 1
        if self.currentTime == 0 {
            loadView.beginAnimation()
        }
        var beginTime = ((dataArray?.first as? AgoraMiguLrcSentence)?.startTime() ?? 0) / time
        if beginTime <= 0 {
            beginTime = (dataArray?.first as? AgoraLrcModel)?.time ?? 0
        }
        if currentTime > beginTime && (dataArray?.count ?? 0) > 0 {
            loadView.hiddenLoadView()
        }
        self.currentTime = currentTime * time
        preTime = currentTime
        updatePerSecond()
    }

    func scrollToTop(animation: Bool = false) {
        guard !tableView.visibleCells.isEmpty else { return }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: animation)
    }

    func scrollToTime(timestamp: TimeInterval) {
        currentTime = timestamp
        updatePerSecond()
    }

    func reset() {
        currentTime = 0
        scrollRow = -1
        preRow = -1
        preIndex = 0
        prePitch = 0
        preWord = nil
        progress = 0
        totalPitchCount = 0
        isLineCallback = false
        miguSongModel = nil
        lrcDatas?.removeAll()
        dataArray?.removeAll()
        tipsLabel.isHidden = true
        tableView.reloadData()
        loadView.isHidden = lrcConfig?.isHiddenWatitingView ?? false
    }

    private func updateUI() {
        tipsLabel.text = _lrcConfig.tipsString
        tipsLabel.textColor = _lrcConfig.tipsColor
        tipsLabel.font = _lrcConfig.tipsFont
        lineView.backgroundColor = _lrcConfig.separatorLineColor
        loadView.lrcConfig = _lrcConfig
        loadView.isHidden = _lrcConfig.isHiddenWatitingView
        tableView.isScrollEnabled = _lrcConfig.isDrag
        gradientLayer.locations = _lrcConfig.bottomMaskLocations
        gradientLayer.colors = _lrcConfig.bottomMaskColors.map { $0.cgColor }
        gradientLayer.isHidden = _lrcConfig.isHiddenBottomMask
        statckView.spacing = _lrcConfig.waitingViewBottomMargin
    }

    // MARK: - 更新歌词的时间

    private var preWord: String?
    private var prePitch: Int = 0
    private var preIndex: Int = 0
    private var isLineCallback: Bool = false
    private func updatePerSecond() {
        if lrcDatas != nil {
            if let lrc = getLrc() {
                scrollRow = lrc.index ?? 0
                progress = lrc.progress ?? 0
                currentPlayerLrc?(lrc.lrcText ?? "", progress)
                if roundToPlaces(value: progress, places: 1) >= 1.0 && isLineCallback == false {
                    currentLineEndsClosure?()
                }
                isLineCallback = roundToPlaces(value: progress, places: 1) >= 1
            }
            return
        }
        if let lrc = getXmlLrc() {
            scrollRow = lrc.index ?? 0
            progress = lrc.progress ?? 0
            currentPlayerLrc?(lrc.lrcText ?? "", progress)
            if roundToPlaces(value: progress, places: 1) >= 1.0 && isLineCallback == false {
                currentLineEndsClosure?()
            }
            isLineCallback = roundToPlaces(value: progress, places: 1) >= 1
            if preIndex != scrollRow {
                currentWordPitchClosure?(lrc.pitch, totalPitchCount)
            } else if preWord != lrc.lrcText || prePitch != lrc.pitch {
                currentWordPitchClosure?(lrc.pitch, totalPitchCount)
                
            }
            preWord = lrc.lrcText
            prePitch = lrc.pitch
            preIndex = scrollRow
        }
    }

    // MARK: - 获取播放歌曲的信息

    // 获取xml类型的歌词信息
    private func getXmlLrc() -> (index: Int?,
                                 lrcText: String?,
                                 progress: CGFloat?, pitch: Int)?
    {
        guard let lrcArray = miguSongModel?.sentences,
              !lrcArray.isEmpty else { return nil }
        var i = 0
        var progress: CGFloat = 0.0
        // 歌词滚动显示
        for (index, lrc) in lrcArray.enumerated() {
            let currentLrc = lrc
            var nextLrc: AgoraMiguLrcSentence?
            // 获取下一句歌词
            var nextStartTime: TimeInterval = 0
            if index == lrcArray.count - 1 {
                nextLrc = lrcArray[index]
                nextStartTime = nextLrc?.endTime() ?? 0
            } else {
                nextLrc = lrcArray[index + 1]
                nextStartTime = nextLrc?.startTime() ?? 0
            }
            if currentTime >= currentLrc.startTime(),
               currentLrc.startTime() > 0,
               currentTime < nextStartTime
            {
                i = index
                let (wordProgress, pitch) = currentLrc.getProgress(with: currentTime)
                progress = wordProgress
                return (i, currentLrc.toSentence(), progress, pitch)
            }
        }
        return nil
    }

    // 获取lrc格式的歌词信息
    func getLrc() -> (index: Int?, lrcText: String?, progress: CGFloat?)? {
        guard let lrcArray = lrcDatas,
              !lrcArray.isEmpty else { return nil }
        var i = 0
        var progress: CGFloat = 0.0
        for (index, lrc) in lrcArray.enumerated() {
            let currrentLrc = lrc
            var nextLrc: AgoraLrcModel?
            // 获取下一句歌词
            if index == lrcArray.count - 1 {
                nextLrc = lrcArray[index]
            } else {
                nextLrc = lrcArray[index + 1]
            }

            if currentTime >= currrentLrc.time, currentTime < (nextLrc?.time ?? 0) {
                i = index
                progress = CGFloat((currentTime - currrentLrc.time) / ((nextLrc?.time ?? 0) - currrentLrc.time))
                return (i, currrentLrc.lrc, progress)
            }
        }
        return nil
    }
    private func roundToPlaces(value: CGFloat, places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(value * divisor) / divisor
    }
}

extension AgoraLrcView: AgoraLoadViewDelegate {
    func getCurrentTime() -> TimeInterval {
        guard let model = dataArray?.first else { return 0 }
        if let xmlModel = model as? AgoraMiguLrcSentence {
            return xmlModel.startTime() / 1000 - currentTime / 1000
        } else if let lrcModel = model as? AgoraLrcModel {
            return lrcModel.time - currentTime
        }
        return 0
    }
}

extension AgoraLrcView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        dataArray?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AgoaraLrcViewCell", for: indexPath) as! AgoraMusicLrcCell
        cell.lrcConfig = _lrcConfig
        let lrcModel = dataArray?[indexPath.row]

        if scrollRow != indexPath.row {
            if lrcModel is AgoraMiguLrcSentence {
                cell.setupMusicXmlLrc(with: lrcModel as? AgoraMiguLrcSentence, progress: 0)
            } else {
                cell.setupMusicLrc(with: lrcModel as? AgoraLrcModel, progress: 0)
            }

            if indexPath.row == 0, preRow < 0 {
                if lrcModel is AgoraMiguLrcSentence {
                    cell.setupCurrentLrcScale(text: (lrcModel as? AgoraMiguLrcSentence)?.toSentence())
                } else {
                    cell.setupCurrentLrcScale(text: (lrcModel as? AgoraLrcModel)?.lrc)
                }
            }

        } else if scrollRow > -1 {
            if lrcModel is AgoraMiguLrcSentence {
                cell.setupCurrentLrcScale(text: (lrcModel as? AgoraMiguLrcSentence)?.toSentence())
            } else {
                cell.setupCurrentLrcScale(text: (lrcModel as? AgoraLrcModel)?.lrc)
            }
        }
        return cell
    }

    func scrollViewWillBeginDragging(_: UIScrollView) {
        isDragging = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate _: Bool) {
        dragCellHandler(scrollView: scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dragCellHandler(scrollView: scrollView)
    }

    private func dragCellHandler(scrollView: UIScrollView) {
        isDragging = false
        let point = CGPoint(x: 0, y: scrollView.contentOffset.y + scrollView.bounds.height * 0.5)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        guard let model = dataArray?[indexPath.row] else { return }
        if let xmlModel = model as? AgoraMiguLrcSentence {
            seekToTime?(xmlModel.startTime() / 1000)
        } else if let lrcModel = model as? AgoraLrcModel {
            seekToTime?(lrcModel.time)
        }
        loadView.hiddenLoadView()
    }
}
