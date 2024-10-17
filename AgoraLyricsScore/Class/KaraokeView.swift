    //
//  KaraokeView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class KaraokeView: UIView {
    /// 背景图
    @objc public var backgroundImage: UIImage? = nil {
        didSet { updateUI() }
    }
    
    /// 是否使用评分功能
    /// - Note: 当为 `false`, 会隐藏评分视图
    @objc public var scoringEnabled: Bool = true {
        didSet { updateUI() }
    }
    
    /// 评分组件和歌词组件之间的间距 默认: 0
    @objc public var spacing: CGFloat = 0 {
        didSet { updateUI() }
    }
    
    @objc public weak var delegate: KaraokeDelegate?
    @objc public let lyricsView = LyricsView()
    @objc public let scoringView = ScoringView()
    fileprivate let backgroundImageView = UIImageView()
    fileprivate var lyricsViewTopConstraint: NSLayoutConstraint!
    fileprivate var scoringViewHeightConstraint, scoringViewTopConstraint: NSLayoutConstraint!
    fileprivate var lyricData: LyricModel?
    fileprivate let progressChecker = ProgressChecker()
    fileprivate var pitchIsZeroCount = 0
    fileprivate var isStart = false
    fileprivate let logTag = "KaraokeView"
    /// use for debug
    fileprivate var lastProgress: UInt = 0
    fileprivate var progressPrintCount = 0
    fileprivate var progressPrintCountMax = 80
    
    /// init
    /// - !!! Only one init method
    /// - Note: can set custom logger
    /// - Note: use for Objective-C. `[[KaraokeView alloc] initWithFrame:frame loggers:@[[ConsoleLogger new], [FileLogger new]]]`
    /// - Note: use for Swift. `KaraokeView(frame: frame)`
    /// - Parameters:
    ///   - logger: custom logger
    @objc public convenience init(frame: CGRect, loggers: [ILogger] = [FileLogger(), ConsoleLogger()]) {
        Log.setLoggers(loggers: loggers)
        self.init(frame: frame)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Not Public, Please use `init(frame, loggers)`
    private override init(frame: CGRect) {
        super.init(frame: frame)
        Log.debug(text: "version \(versionName)", tag: logTag)
        setupUI()
        commonInit()
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
}

// MARK: - Public Method
extension KaraokeView {
    /// 解析歌词文件
    /// - Parameters:
    ///   - lyricFileData: 歌词文件的内容（xml、krc、lrc）
    ///   - pitchFileData: pitch文件的内容
    ///   - includeCopyrightSentence: 句子是否需要包含版本信息(只在pitchFileData不为空，且krc类型歌词有效)
    /// - Returns: 歌词信息
    @objc public static func parseLyricData(lyricFileData: Data,
                                            pitchFileData: Data? = nil,
                                            lyricOffset: Int = 0,
                                            includeCopyrightSentence: Bool = true) -> LyricModel? {
        let parser = Parser()
        return parser.parseLyricData(data: lyricFileData,
                                     pitchFileData: pitchFileData,
                                     lyricOffset: lyricOffset,
                                     includeCopyrightSentence: includeCopyrightSentence)
    }
    
    /// 设置歌词数据信息
    /// - Parameter data: 歌词信息 由 `parseLyricData(data: Data)` 生成. 如果纯音乐, 给 `nil`.
    /// - Parameter usingInternalScoring: 是否需要歌词组件内部计算打分, 当`data`为`nil`，此值忽略。
    @objc public func setLyricData(data: LyricModel?, usingInternalScoring: Bool) {
        Log.info(text: "setLyricData \(data?.name ?? "nil")", tag: logTag)
        if !Thread.isMainThread {
            Log.error(error: "invoke setLyricData not isMainThread ", tag: logTag)
        }
        
        /** Fix incorrect value of tableView.Height in lyricsView, after update scoringView.height/topSpace **/
        layoutIfNeeded()
        
        lyricData = data
        
        /** 无歌词状态下强制关闭 **/
        if data == nil {
            scoringEnabled = false
        }
        
        lyricsView.setLyricData(data: data)
        scoringView.setLyricData(data: data, usingInternalScoring: usingInternalScoring)
        isStart = true
    }
    
    /// 重置, 歌曲停止、切歌需要调用
    @objc public func reset() {
        Log.info(text: "reset", tag: logTag)
        if !Thread.isMainThread {
            Log.error(error: "invoke reset not isMainThread ", tag: logTag)
        }
        progressChecker.reset()
        isStart = false
        pitchIsZeroCount = 0
        lastProgress = 0
        progressPrintCount = 0
        lyricsView.reset()
        scoringView.reset()
    }
    
    /// 设置实时音高
    /// - Note: 获取方式1，从Agora RTC 回调方法`reportAudioVolumeIndicationOfSpeakers` 获取speakerPitch。
    /// - Note: 获取方式2，可以从AgoraContentCenterEx回调方法 `onPitch`[该回调频率是50ms/次] 获取speakerPitch。
    /// - note: 获取方式3，从mcc `OnPitch` 获取speakerPitch和score。
    /// - Parameter speakerPitch: 演唱者的实时音高值。
    /// - Parameter progressInMs: 当前音高、得分对应的实时进度（ms）.方式1给0.
    /// - Parameter progressInMs: 当前得分。方式1、2给0。
    @objc public func setPitch(speakerPitch: Double, progressInMs: UInt, score: UInt) {
        guard scoringEnabled else { return }
        if !Thread.isMainThread {
            Log.error(error: "invoke setPitch not isMainThread ", tag: logTag)
        }
        if speakerPitch < 0 { return }
        guard isStart else { return }
        
        scoringView.setPitch(speakerPitch: speakerPitch, progressInMs: progressInMs, score: score)
    }
    
    /// 设置当前歌曲的进度
    /// - Note: 可以获取播放器的当前进度进行设置
    /// - Parameter progress: 歌曲进度 (ms)
    @objc public func setProgress(progress: UInt) {
        
        if !Thread.isMainThread {
            Log.error(error: "invoke setProgress not isMainThread ", tag: logTag)
        }
        guard isStart else { return }
        logProgressIfNeed(progress: progress)
        lyricsView.setProgress(progress: progress)
        if scoringEnabled {
            scoringView.progress = progress
        }
        progressChecker.set(progress: progress)
    }
    
    /// 设置自定义分数计算对象
    /// - Note: 如果不调用此方法，则内部使用默认计分规则
    /// - Parameter algorithm: 遵循`IScoreAlgorithm`协议实现的对象
    @objc public func setScoreAlgorithm(algorithm: IScoreAlgorithm) {
        if !Thread.isMainThread {
            Log.error(error: "invoke setScoreAlgorithm not isMainThread ", tag: logTag)
        }
        scoringView.setScoreAlgorithm(algorithm: algorithm)
    }
    
    /// 设置打分难易程度(难度系数)
    /// - Note: 值越小打分难度越小，值越高打分难度越大
    /// - Parameter level: 系数, 范围：[0, 100], 如不设置默认为15
    @objc public func setScoreLevel(level: Int) {
        if !Thread.isMainThread {
            Log.error(error: "invoke setScoreLevel not isMainThread ", tag: logTag)
        }
        if level < 0 || level > 100 {
            Log.error(error: "setScoreLevel out bounds \(level), [0, 100]", tag: logTag)
            return
        }
        scoringView.scoreLevel = level
    }
    
    /// 设置打分分值补偿
    /// - Note: 在计算分值的时候作为补偿
    /// - Parameter offset: 分值补偿 [-100, 100], 如不设置默认为0
    @objc public func setScoreCompensationOffset(offset: Int) {
        if !Thread.isMainThread {
            Log.error(error: "invoke setScoreCompensationOffset not isMainThread ", tag: logTag)
        }
        if offset < -100 || offset > 100 {
            Log.error(error: "setScoreCompensationOffset out bounds \(offset), [-100, 100]", tag: logTag)
            return
        }
        scoringView.scoreCompensationOffset = offset
    }
}

// MARK: - UI
extension KaraokeView {
    fileprivate func setupUI() {
        scoringView.backgroundColor = .clear
        lyricsView.backgroundColor = .clear
        
        backgroundImageView.isHidden = true
        
        addSubview(backgroundImageView)
        addSubview(scoringView)
        addSubview(lyricsView)
        
        scoringView.translatesAutoresizingMaskIntoConstraints = false
        lyricsView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        scoringView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scoringView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scoringViewHeightConstraint = scoringView.heightAnchor.constraint(equalToConstant: scoringView.viewHeight)
        scoringViewHeightConstraint.isActive = true
        scoringViewTopConstraint = scoringView.topAnchor.constraint(equalTo: topAnchor, constant: scoringView.topSpaces)
        scoringViewTopConstraint.isActive = true
        
        lyricsView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        lyricsView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        lyricsViewTopConstraint = lyricsView.topAnchor.constraint(equalTo: scoringView.bottomAnchor, constant: spacing)
        lyricsViewTopConstraint.isActive = true
        lyricsView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        backgroundImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        backgroundImageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        backgroundImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    fileprivate func commonInit() {
        lyricsView.delegate = self
        scoringView.delegate = self
        progressChecker.delegate = self
    }
    
    fileprivate func updateUI() {
        backgroundImageView.image = backgroundImage
        backgroundImageView.isHidden = backgroundImage == nil
        lyricsViewTopConstraint.constant = scoringEnabled ? spacing : 0 - scoringView.viewHeight
        scoringViewHeightConstraint.constant = scoringView.viewHeight
        scoringView.isHidden = !scoringEnabled
        scoringViewTopConstraint.constant = scoringView.topSpaces
    }
    
    fileprivate var versionName: String {
        guard let version = Bundle.currentBundle.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "unknow version"
        }
        return version
    }
}

// MARK: - ProgressCheckerDelegate
extension KaraokeView: LyricsViewDelegate {
    func onLyricsViewBegainDrag(view: LyricsView) {
        scoringView.dragBegain()
    }
    
    func onLyricsView(view: LyricsView, didDragTo position: UInt) {
        Log.debug(text: "=== didDragTo \(position)", tag: "drag")
        scoringView.dragDidEnd(position: position)
        delegate?.onKaraokeView?(view: self, didDragTo: position)
    }
}

// MARK: - ProgressCheckerDelegate
extension KaraokeView: ScoringViewDelegate {
    func scoringViewShouldUpdateViewLayout(view: ScoringView) {
        updateUI()
    }
    
    func scoringView(_ view: ScoringView,
                     didFinishLineWith model: LyricLineModel,
                     score: Int,
                     cumulativeScore: Int,
                     lineIndex: Int,
                     lineCount: Int) {
        Log.info(text: "didFinishLineWith score:\(score) lineIndex:\(lineIndex) lineCount:\(lineCount) cumulativeScore:\(cumulativeScore)", tag: logTag)
        delegate?.onKaraokeView?(view: self,
                                 didFinishLineWith: model,
                                 score: score,
                                 cumulativeScore: cumulativeScore,
                                 lineIndex: lineIndex,
                                 lineCount: lineCount)
    }
}

extension KaraokeView: ProgressCheckerDelegate {
    func progressCheckerDidProgressPause() {
        Log.debug(text: "progressCheckerDidProgressPause", tag: logTag)
        scoringView.forceStopIndicatorAnimationWhenReachingContinuousZeros()
    }
}

// MARK: -- Log
extension KaraokeView {
    func logProgressIfNeed(progress: UInt) {
        let gap = abs(Int32(progress) - Int32(lastProgress))
        if progressPrintCount < progressPrintCountMax, gap > 20 {
            let text = "setProgress:\(progress) last:\(lastProgress) gap:\(gap)"
            Log.warning(text: text, tag: logTag)
            progressPrintCount += 1
        }
        lastProgress = progress
    }
}
