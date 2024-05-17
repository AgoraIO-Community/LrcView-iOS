    //
//  KaraokeView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class KaraokeViewEx: UIView {
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
    
    @objc public weak var delegate: KaraokeDelegateEx?
    @objc public let lyricsView = LyricsViewEx()
    @objc public let scoringView = ScoringViewEx()
    fileprivate let backgroundImageView = UIImageView()
    fileprivate var lyricsViewTopConstraint: NSLayoutConstraint!
    fileprivate var scoringViewHeightConstraint, scoringViewTopConstraint: NSLayoutConstraint!
    fileprivate var lyricData: LyricModelEx?
    fileprivate let progressChecker = ProgressChecker()
    fileprivate var pitchIsZeroCount = 0
    fileprivate var isStart = false
    fileprivate let logTag = "KaraokeViewEx"
    /// use for debug
    fileprivate var lastProgress: UInt = 0
    fileprivate var progressPrintCount = 0
    fileprivate var progressPrintCountMax = 80
    
    /// init
    /// - !!! Only one init method
    /// - Note: can set custom logger
    /// - Note: use for Objective-C. `[[KaraokeViewEx alloc] initWithFrame:frame loggers:@[[ConsoleLogger new], [FileLogger new]]]`
    /// - Note: use for Swift. `KaraokeViewEx(frame: frame)`
    /// - Parameters:
    ///   - logger: custom logger
    @objc public convenience init(frame: CGRect, loggers: [ILoggerEx] = [FileLoggerEx(), ConsoleLoggerEx()]) {
        Log.setLoggers(loggers: loggers)
        self.init(frame: frame)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Not Public, Please use `init(frame, loggers)`
    override init(frame: CGRect) {
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
extension KaraokeViewEx {
    /// 解析歌词文件krc
    /// - Parameters:
    ///   - krcFileData: krc文件的内容
    ///   - pitchFileData: pitch文件的内容
    ///   - includeCopyrightSentence: 是否需要包含版本信息类型的句子
    /// - Returns: 歌词信息
    @objc public static func parseLyricData(krcFileData: Data,
                                            pitchFileData: Data,
                                            includeCopyrightSentence: Bool = true) -> LyricModelEx? {
        let parser = Parser()
        return parser.parseLyricData(krcFileData: krcFileData,
                                     pitchFileData: pitchFileData,
                                     includeCopyrightSentence: includeCopyrightSentence)
    }
    
    /// 设置歌词数据信息
    /// - Parameter data: 歌词信息 由 `parseLyricData(data: Data)` 生成. 如果纯音乐, 给 `nil`.
    @objc public func setLyricData(data: LyricModelEx?) {
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
        scoringView.setLyricData(data: data)
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
    
    /// 设置当前歌曲的进度
    /// - Note: 可以获取播放器的当前进度进行设置
    /// - Parameter progress: 歌曲进度 (ms)
    @objc public func setProgress(progressInMs: UInt) {
        if !Thread.isMainThread {
            Log.error(error: "invoke setProgress not isMainThread ", tag: logTag)
        }
        guard isStart else { return }
        logProgressIfNeed(progress: progressInMs)
        lyricsView.setProgress(progress: progressInMs)
        scoringView.progress = progressInMs
        progressChecker.set(progress: progressInMs)
    }
    
    /// 设置实时采集(mic)的Pitch
    /// - Note: 可以从AgoraRTC DRM回调方法 `onPitch`[该回调频率是50ms/次]  获取
    /// - Parameter speakerPitch: 演唱者的实时音高值
    /// - Parameter progressInMs: 当前音高、得分对应的实时进度（ms）
    @objc public func setPitch(speakerPitch: Double, progressInMs: UInt) {
        if !Thread.isMainThread {
            Log.error(error: "invoke setProgress not isMainThread ", tag: logTag)
        }
        guard isStart else { return }
        
        Log.info(text: "p:\(speakerPitch)", tag: logTag)
        if !Thread.isMainThread {
            Log.error(error: "invoke setPitch not isMainThread ", tag: logTag)
        }
        if speakerPitch < 0 { return }
        guard isStart else { return }
        if speakerPitch == 0 {
            pitchIsZeroCount += 1
        }
        else {
            pitchIsZeroCount = 0
        }
        if speakerPitch > 0 || pitchIsZeroCount >= 10 { /** 过滤10个0的情况* **/
            pitchIsZeroCount = 0
            scoringView.setPitch(speakerPitch: speakerPitch,
                                 progressInMs: progressInMs)
        }
    }
}

// MARK: - UI
extension KaraokeViewEx {
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
extension KaraokeViewEx: LyricsViewDelegate {
    func onLyricsViewBegainDrag(view: LyricsViewEx) {
        scoringView.dragBegain()
    }
    
    func onLyricsView(view: LyricsViewEx, didDragTo position: UInt) {
        Log.debug(text: "=== didDragTo \(position)", tag: "drag")
        scoringView.dragDidEnd(position: position)
        delegate?.onKaraokeViewEx?(view: self, didDragTo: position)
    }
}

// MARK: - ProgressCheckerDelegate
extension KaraokeViewEx: ScoringViewDelegate {
    func scoringViewShouldUpdateViewLayout(view: ScoringViewEx) {
        updateUI()
    }
}

extension KaraokeViewEx: ProgressCheckerDelegate {
    func progressCheckerDidProgressPause() {
        Log.debug(text: "progressCheckerDidProgressPause", tag: logTag)
        scoringView.forceStopIndicatorAnimationWhenReachingContinuousZeros()
    }
}

// MARK: -- Log
extension KaraokeViewEx {
    func logProgressIfNeed(progress: UInt) {
        let gap = Int(progress) - Int(lastProgress)
        if progressPrintCount < progressPrintCountMax, gap > 20 {
            let text = "setProgress:\(progress) last:\(lastProgress) gap:\(progress-lastProgress)"
            Log.warning(text: text, tag: logTag)
            progressPrintCount += 1
        }
        lastProgress = progress
    }
}
