//
//  MainTestController.swift
//  Demo
//
//  Created by ZYP on 2023/1/30.
//

import UIKit
import AgoraRtcKit
import TokenBuilder
import AgoraLyricsScore

class MainTestVC: UIViewController {
    let karaokeView = KaraokeView()
    let gradeView = GradeView()
    let incentiveView = IncentiveView()
    let skipButton = UIButton()
    let setButton = UIButton()
    var agoraKit: AgoraRtcEngineKit!
    var token: String!
    var mcc: AgoraMusicContentCenter!
    var mpk: AgoraMusicPlayerProtocol!
    var songCode = 6599298157850480 /// 十年
    private var timer = GCDTimer()
    var cumulativeScore = 0
    var lyricModel: LyricModel!
    var noLyric = false
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
        view.layoutIfNeeded()
        gradeView.setup()
    }
    
    func setupUI() {
//        karaokeView.scoringView.viewHeight = 160
//        karaokeView.scoringView.topSpaces = 50
        
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
        karaokeView.scoringView.viewHeight = 160
        karaokeView.scoringView.topSpaces = 65
        karaokeView.lyricsView.draggable = true
        karaokeView.spacing = 0.79
        karaokeView.scoringView.showDebugView = false
        
        skipButton.setTitle("跳过前奏", for: .normal)
        setButton.setTitle("设置参数", for: .normal)
        skipButton.backgroundColor = .red
        setButton.backgroundColor = .red
        
        view.backgroundColor = .black
        view.addSubview(karaokeView)
        view.addSubview(gradeView)
        view.addSubview(incentiveView)
        view.addSubview(skipButton)
        view.addSubview(setButton)
        
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        gradeView.translatesAutoresizingMaskIntoConstraints = false
        incentiveView.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        setButton.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
        
        gradeView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: 15).isActive = true
        gradeView.leftAnchor.constraint(equalTo: karaokeView.leftAnchor, constant: 15).isActive = true
        gradeView.rightAnchor.constraint(equalTo: karaokeView.rightAnchor, constant: -15).isActive = true
        gradeView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        incentiveView.heightAnchor.constraint(equalToConstant: incentiveView.heigth).isActive = true
        incentiveView.widthAnchor.constraint(equalToConstant: incentiveView.width).isActive = true
        incentiveView.topAnchor.constraint(equalTo: gradeView.bottomAnchor, constant: 15).isActive = true
        incentiveView.centerXAnchor.constraint(equalTo: karaokeView.centerXAnchor, constant: -10).isActive = true
        
        skipButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 100).isActive = true
        skipButton.topAnchor.constraint(equalTo: karaokeView.bottomAnchor, constant: 30).isActive = true
        
        setButton.leftAnchor.constraint(equalTo: skipButton.rightAnchor, constant: 45).isActive = true
        setButton.topAnchor.constraint(equalTo: karaokeView.bottomAnchor, constant: 30).isActive = true
    }
    
    func commonInit() {
        skipButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        setButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        cumulativeScore = 0
        token = TokenBuilder.buildToken(Config.mccAppId,
                                        appCertificate: Config.mccCertificate,
                                        userUuid: "\(Config.mccUid)")
        initEngine()
        joinChannel()
        initMCC()
        mccPreload()
        karaokeView.delegate = self
    }
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }
    
    func joinChannel() { /** 目的：发布mic流、接收音频流 **/
        agoraKit.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        agoraKit.setClientRole(.broadcaster)
        let ret = agoraKit.joinChannel(byToken: nil,
                                       channelId: Config.channelId,
                                       uid: Config.hostUid,
                                       mediaOptions: option)
        print("joinChannel ret \(ret)")
    }
    
    func initMCC() {
        let config = AgoraMusicContentCenterConfig()
        config.rtcEngine = agoraKit
        config.mccUid = Config.mccUid
        config.token = token
        config.appId = Config.mccAppId
        mcc = AgoraMusicContentCenter.sharedContentCenter(config: config)
        mcc.register(self)
        mpk = mcc.createMusicPlayer(delegate: self)
    }
    
    func mccPreload() {
        let ret = mcc.preload(songCode: songCode, jsonOption: nil)
        if ret != 0 {
            print("preload error \(ret)")
            return
        }
        print("== preload success")
    }
    
    func mccOpen() {
        let ret = mpk.openMedia(songCode: songCode, startPos: 0)
        if ret != 0 {
            print("openMedia error \(ret)")
            return
        }
        print("== openMedia success")
    }
    
    var last = 0
    func mccPlay() {
        let ret = mpk.play()
        if ret != 0 {
            print("play error \(ret)")
            return
        }
        print("== play success")
        self.last = 0
        timer.scheduledMillisecondsTimer(withName: "MainTestVC",
                                         countDown: 1000000,
                                         milliseconds: 10,
                                         queue: .main) { [weak self](_, time) in
            
            guard let self = self else { return }
            
            var current = self.last
            if time.truncatingRemainder(dividingBy: 1000) == 0 {
                current = self.mpk.getPosition()
            }
            
            current += 10
            
            self.last = current
            var time = current
            if time > 250 { /** 进度提前250ms **/
                time -= 250
            }
            self.karaokeView.setProgress(progress: current )
        }
    }
    
    func mccGetLrc() {
        let requestId = mcc.getLyric(songCode: songCode, lyricType: 0)
        print("== mccGetLrc requestId:\(requestId)")
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        if sender == skipButton {
            if let data = lyricModel {
                mpk.seek(toPosition: data.preludeEndPosition - 2000)
            }
            return
        }
        
        let vc = ParamSetVC()
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
    
    func updateView(param: Param) {
        karaokeView.backgroundImage = param.karaoke.backgroundImage
        karaokeView.scoringEnabled = param.karaoke.scoringEnabled
        karaokeView.spacing = param.karaoke.spacing
        karaokeView.setScoreLevel(level: param.karaoke.scoreLevel)
        karaokeView.setScoreCompensationOffset(offset: param.karaoke.scoreCompensationOffset)
        
        karaokeView.lyricsView.lyricLineSpacing = param.lyric.lyricLineSpacing
        karaokeView.lyricsView.noLyricTipsColor = param.lyric.noLyricTipsColor
        karaokeView.lyricsView.noLyricTipsText = param.lyric.noLyricTipsText
        karaokeView.lyricsView.textHighlightFontSize = param.lyric.textHighlightFontSize
        karaokeView.lyricsView.textNormalColor = param.lyric.textNormalColor
        karaokeView.lyricsView.textSelectedColor = param.lyric.textSelectedColor
        karaokeView.lyricsView.textHighlightedColor = param.lyric.textHighlightedColor
        karaokeView.lyricsView.waitingViewHidden = param.lyric.waitingViewHidden
        karaokeView.lyricsView.firstToneHintViewStyle.backgroundColor = param.lyric.firstToneHintViewStyle.backgroundColor
        karaokeView.lyricsView.firstToneHintViewStyle.size = param.lyric.firstToneHintViewStyle.size
        karaokeView.lyricsView.firstToneHintViewStyle.bottomMargin = param.lyric.firstToneHintViewStyle.bottomMargin
        karaokeView.lyricsView.maxWidth = param.lyric.maxWidth
        karaokeView.lyricsView.draggable = param.lyric.draggable
//        param.lyric.firstToneHintViewStyle
        
        karaokeView.scoringView.particleEffectHidden = param.scoring.particleEffectHidden
        karaokeView.scoringView.emitterImages = param.scoring.emitterImages
        karaokeView.scoringView.standardPitchStickViewHighlightColor = param.scoring.standardPitchStickViewHighlightColor
        karaokeView.scoringView.standardPitchStickViewColor = param.scoring.standardPitchStickViewColor
        karaokeView.scoringView.standardPitchStickViewHeight = param.scoring.standardPitchStickViewHeight
        karaokeView.scoringView.defaultPitchCursorX = param.scoring.defaultPitchCursorX
        karaokeView.scoringView.topSpaces = param.scoring.topSpaces
        karaokeView.scoringView.viewHeight = param.scoring.viewHeight
        karaokeView.scoringView.hitScoreThreshold = param.scoring.hitScoreThreshold
        karaokeView.scoringView.movingSpeedFactor = param.scoring.movingSpeedFactor
        karaokeView.scoringView.showDebugView = param.scoring.showDebugView
    }
}

extension MainTestVC: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError \(errorCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("didJoinedOfUid \(uid)")
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("didJoinChannel withUid \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        if let pitch = speakers.last?.voicePitch {
            karaokeView.setPitch(pitch: pitch)
        }
    }
}

extension MainTestVC: AgoraMusicContentCenterEventDelegate {
    func onMusicChartsResult(_ requestId: String, status: AgoraMusicContentCenterStatusCode, result: [AgoraMusicChartInfo]) {
        
    }
    
    func onMusicCollectionResult(_ requestId: String, status: AgoraMusicContentCenterStatusCode, result: AgoraMusicCollection) {
    }
    
    func onLyricResult(_ requestId: String, lyricUrl: String) {
        print("=== onLyricResult requestId:\(requestId) lyricUrl:\(lyricUrl)")
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "745012", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        let model = KaraokeView.parseLyricData(data: data)!
        self.lyricModel = model
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            if !self.noLyric {
                self.karaokeView.setLyricData(data: model)
                self.gradeView.setTitle(title: "\(model.name) - \(model.singer)")
                self.gradeView.isHidden = false
            }
            else {
                self.karaokeView.setLyricData(data: nil)
                self.gradeView.isHidden = true
            }
            
            self.mccPlay()
        }
        
    }
    
    func onPreLoadEvent(_ songCode: Int,
                        percent: Int,
                        status: AgoraMusicContentCenterPreloadStatus,
                        msg: String, lyricUrl: String) {
        print("== onPreLoadEvent \(status.rawValue) msg: \(msg)")
        if status == .OK { /** preload 成功 **/
            print("== preload ok")
            mccOpen()
        }
        
        if status == .error {
            print("onPreLoadEvent percent:\(percent) status:\(status.rawValue) msg:\(msg) lyricUrl:\(lyricUrl)")
        }
    }
}


extension MainTestVC: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            print("=== openCompleted")
            mccGetLrc()
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo position: Int) {}
}

extension MainTestVC: KaraokeDelegate {
    func onKaraokeView(view: KaraokeView, didDragTo position: Int) {
        self.last = position + 250
        mpk.seek(toPosition: position)
        cumulativeScore = view.scoringView.getCumulativeScore()
        gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: lyricModel.lines.count * 100)
    }
    
    func onKaraokeView(view: KaraokeView,
                       didFinishLineWith model: LyricLineModel,
                       score: Int,
                       cumulativeScore: Int,
                       lineIndex: Int,
                       lineCount: Int) {
        self.cumulativeScore = cumulativeScore
        gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: lineCount * 100)
        incentiveView.show(score: score)
    }
}

extension MainTestVC: ParamSetVCDelegate {
    func didSetParam(param: Param, noLyric: Bool) {
        self.noLyric = noLyric
        mpk.stop()
        timer.destoryTimer(withName: "MainTestVC")
        self.last = 0
        karaokeView.reset()
        updateView(param: param)
        mccPreload()
    }
}
