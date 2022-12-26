//
//  KaraokeView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class KaraokeView: UIView {
    /// 背景图
    public var backgroundImage: UIImage? = nil {
        didSet {
            updateUI()
        }
    }
    
    /// 是否使用评分功能
    /// - Note: 当`LyricModel.hasPitch = false`，强制不使用
    /// - Note: 当为 `false`, 会隐藏评分视图
    public var scoringEnabled: Bool = true {
        didSet {
            updateUI()
        }
    }
    
    /// 评分组件和歌词组件之间的间距 默认: 0
    public var spacing: CGFloat = 0 {
        didSet {
            updateUI()
        }
    }
    
    public weak var delegate: KaraokeDelegate?
    public let lyricsView = LyricsView()
    public let scoringView = ScoringView()
    fileprivate let backgroundImageView = UIImageView()
    fileprivate var lyricsViewTopConstraint: NSLayoutConstraint!
    fileprivate var lyricData: LyricModel!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public Method
extension KaraokeView {
    /// 重置, 歌曲停止、切歌需要调用
    public func reset() {
        lyricsView.reset()
    }
    
    /// 解析歌词文件xml数据
    /// - Parameter data: xml二进制数据
    /// - Returns: 歌词信息
    public static func parseLyricData(data: Data) -> LyricModel? {
        let parser = Parser()
        return parser.parseLyricData(data: data)
    }
    
    /// 设置歌词数据信息
    /// - Parameter data: 歌词信息 由 `parseLyricData(data: Data)` 生成. 如果纯音乐, 给 `.empty`.
    public func setLyricData(data: LyricModel) {
        lyricData = data
        if data.isEmpty { /** 无歌词状态下强制关闭 **/
            scoringEnabled = false
        }
        lyricsView.setLyricData(data: data)
    }
    
    /// 设置实时采集(mic)的Pitch
    /// - Note: 可以从AgoraRTC回调方法 `- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine reportAudioVolumeIndicationOfSpeakers:(NSArray<AgoraRtcAudioVolumeInfo *> * _Nonnull)speakers totalVolume:(NSInteger)totalVolume`  获取
    /// - Parameter pitch: 实时音调值
    public func setPitch(pitch: Double) {}
    
    /// 设置当前歌曲的进度
    /// - Note: 可以获取播放器的当前进度进行设置
    /// - Parameter progress: 歌曲进度 (ms)
    public func setProgress(progress: Int) {
        var t = progress
        if t > 250 {
            t -= 250
        }
        lyricsView.setProgress(progress: t)
    }
    
    /// 设置自定义分数计算对象
    /// - Note: 如果不调用此方法，则内部使用默认计分规则
    /// - Parameter algorithm: 遵循`IScoreAlgorithm`协议实现的对象
    public func setScoreAlgorithm(algorithm: IScoreAlgorithm) {}
    
    /// 设置打分难易程度(难度系数)
    /// - Note: 值越小打分难度越小，值越高打分难度越大
    /// - Parameter level: 系数, 范围：[0, 100], 如不设置默认为10
    public func setScoreLevel(level: Int) {}
    
    /// 设置打分分值补偿
    /// - Note: 在计算分值的时候作为补偿
    /// - Parameter offset: 分值补偿 [-100, 100], 如不设置默认为0
    public func setScoreCompensationOffset(offset: Int) {}
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
        scoringView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scoringView.heightAnchor.constraint(equalToConstant: scoringView.viewHeight).isActive = true
        
        lyricsView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        lyricsView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        lyricsViewTopConstraint = lyricsView.topAnchor.constraint(equalTo: topAnchor, constant: scoringView.viewHeight + spacing)
        lyricsViewTopConstraint.isActive = true
        lyricsView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        backgroundImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        backgroundImageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        backgroundImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    fileprivate func commonInit() {
        lyricsView.delegate = self
    }
    
    fileprivate func updateUI() {
        backgroundImageView.image = backgroundImage
        backgroundImageView.isHidden = backgroundImage == nil
        
        lyricsViewTopConstraint.constant = scoringEnabled ? scoringView.viewHeight + spacing : 0
        
        scoringView.isHidden = !scoringEnabled
    }
}

extension KaraokeView: LyricsViewDelegate {
    func onLyricsView(view: LyricsView, didDragTo position: Int) {
        delegate?.onKaraokeView?(view: self, didDragTo: position)
    }
}