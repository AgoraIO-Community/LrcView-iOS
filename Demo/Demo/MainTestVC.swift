//
//  MainTestController.swift
//  Demo
//
//  Created by ZYP on 2023/1/30.
//

import UIKit
import AgoraRtcKit
import RTMTokenBuilder
import AgoraLyricsScore
import ScoreEffectUI

class MainTestVC: UIViewController {
    let karaokeView = KaraokeView(frame: .zero, loggers: [FileLogger()])
    let lineScoreView = LineScoreView()
    let gradeView = GradeView()
    let incentiveView = IncentiveView()
    let skipButton = UIButton()
    let setButton = UIButton()
    let quickButton = UIButton()
    let changeButton = UIButton()
    var agoraKit: AgoraRtcEngineKit!
    var token: String!
    var mcc: AgoraMusicContentCenter!
    var mpk: AgoraMusicPlayerProtocol!
    var songCode = 6625526605291650
    /// 0：十年， 1: 王菲 2:晴天
    var songCodes = [6625526605291650, 6599297819205290, 6625526603296890]
    var currentSongIndex = 0
    private var timer = GCDTimer()
    var cumulativeScore = 0
    var lyricModel: LyricModel!
    var noLyric = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    deinit {
        print("=== deinit")
    }
    
    func setupUI() {
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
        karaokeView.scoringView.viewHeight = 100
        karaokeView.scoringView.topSpaces = 80
        karaokeView.lyricsView.showDebugView = false
        karaokeView.lyricsView.draggable = true
        
        skipButton.setTitle("跳过前奏", for: .normal)
        setButton.setTitle("设置参数", for: .normal)
        changeButton.setTitle("切歌", for: .normal)
        quickButton.setTitle("退出", for: .normal)
        skipButton.backgroundColor = .red
        setButton.backgroundColor = .red
        changeButton.backgroundColor = .red
        quickButton.backgroundColor = .red
        
        view.backgroundColor = .black
        view.addSubview(karaokeView)
        view.addSubview(gradeView)
        view.addSubview(incentiveView)
        view.addSubview(skipButton)
        view.addSubview(setButton)
        view.addSubview(changeButton)
        view.addSubview(quickButton)
        view.addSubview(lineScoreView)
        
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        gradeView.translatesAutoresizingMaskIntoConstraints = false
        incentiveView.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        setButton.translatesAutoresizingMaskIntoConstraints = false
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        quickButton.translatesAutoresizingMaskIntoConstraints = false
        lineScoreView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
        
        gradeView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: 15).isActive = true
        gradeView.leftAnchor.constraint(equalTo: karaokeView.leftAnchor, constant: 15).isActive = true
        gradeView.rightAnchor.constraint(equalTo: karaokeView.rightAnchor, constant: -15).isActive = true
        gradeView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        incentiveView.centerYAnchor.constraint(equalTo: karaokeView.scoringView.centerYAnchor).isActive = true
        incentiveView.centerXAnchor.constraint(equalTo: karaokeView.centerXAnchor, constant: -10).isActive = true
        
        lineScoreView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: karaokeView.scoringView.defaultPitchCursorX).isActive = true
        lineScoreView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: karaokeView.scoringView.topSpaces).isActive = true
        lineScoreView.heightAnchor.constraint(equalToConstant: karaokeView.scoringView.viewHeight).isActive = true
        lineScoreView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        skipButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 100).isActive = true
        skipButton.topAnchor.constraint(equalTo: karaokeView.bottomAnchor, constant: 30).isActive = true
        
        setButton.leftAnchor.constraint(equalTo: skipButton.rightAnchor, constant: 45).isActive = true
        setButton.topAnchor.constraint(equalTo: karaokeView.bottomAnchor, constant: 30).isActive = true
        
        changeButton.leftAnchor.constraint(equalTo: skipButton.leftAnchor).isActive = true
        changeButton.topAnchor.constraint(equalTo: setButton.bottomAnchor, constant: 30).isActive = true
        
        quickButton.leftAnchor.constraint(equalTo: setButton.leftAnchor).isActive = true
        quickButton.topAnchor.constraint(equalTo: setButton.bottomAnchor, constant: 30).isActive = true
    }
    
    func commonInit() {
        skipButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        setButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        changeButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        quickButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
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
        agoraKit.enableAudio()
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
                                         milliseconds: 20,
                                         queue: .main) { [weak self](_, time) in

            guard let self = self else { return }

            var current = self.last
            if time.truncatingRemainder(dividingBy: 1000) == 0 {
                current = self.mpk.getPosition()
            }
            current += 20

            self.last = current
            var time = current
            if time > 250 { /** 进度提前250ms, 第一个句子的第一个字得到更好匹配 **/
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
        switch sender {
        case skipButton:
            if let data = lyricModel {
                mpk.seek(toPosition: data.preludeEndPosition - 2000)
            }
            return
        case setButton:
            let vc = ParamSetVC()
            vc.delegate = self
            vc.modalPresentationStyle = .pageSheet
            present(vc, animated: true)
            return
        case changeButton:
            currentSongIndex += 1
            if currentSongIndex >= songCodes.count {
                currentSongIndex = 0
            }
            songCode = songCodes[currentSongIndex]
            mpk.stop()
            timer.destoryTimer(withName: "MainTestVC")
            self.last = 0
            incentiveView.reset()
            gradeView.reset()
            karaokeView.reset()
//            mccPreload()
            return
        case quickButton:
            agoraKit.disableAudio()
            timer.destoryAllTimer()
            mpk.stop()
            mcc.register(nil)
            agoraKit.destroyMediaPlayer(mpk)
            karaokeView.reset()
            gradeView.reset()
            incentiveView.reset()
            navigationController?.popViewController(animated: true)
            return
        default:
            break
        }
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
        karaokeView.lyricsView.noLyricTipsFont = param.lyric.noLyricTipsFont
        karaokeView.lyricsView.textHighlightFontSize = param.lyric.textHighlightFontSize
        karaokeView.lyricsView.textNormalColor = param.lyric.textNormalColor
        karaokeView.lyricsView.textSelectedColor = param.lyric.textSelectedColor
        karaokeView.lyricsView.textHighlightedColor = param.lyric.textHighlightedColor
        karaokeView.lyricsView.waitingViewHidden = param.lyric.waitingViewHidden
        karaokeView.lyricsView.textNormalFontSize = param.lyric.textNormalFontSize
        karaokeView.lyricsView.firstToneHintViewStyle.backgroundColor = param.lyric.firstToneHintViewStyle.backgroundColor
        karaokeView.lyricsView.firstToneHintViewStyle.size = param.lyric.firstToneHintViewStyle.size
        karaokeView.lyricsView.firstToneHintViewStyle.bottomMargin = param.lyric.firstToneHintViewStyle.bottomMargin
        karaokeView.lyricsView.maxWidth = param.lyric.maxWidth
        karaokeView.lyricsView.draggable = param.lyric.draggable
        
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
        
//        let filePath = Bundle.main.path(forResource: "745012", ofType: "xml")!
//        DispatchQueue.main.async {
//            let url = URL(fileURLWithPath: filePath)
//            let data = try! Data(contentsOf: url)
//            let model = KaraokeView.parseLyricData(data: data)!
//            self.lyricModel = model
//            if !self.noLyric {
//                self.karaokeView.setLyricData(data: model)
//                self.gradeView.setTitle(title: "\(model.name) - \(model.singer)")
//                self.gradeView.isHidden = false
//            }
//            else {
//                self.karaokeView.setLyricData(data: nil)
//                self.gradeView.isHidden = true
//            }
//            self.mccPlay()
//        }
        FileCache.fect(urlString: lyricUrl) { progress in

        } completion: { filePath in
            let url = URL(fileURLWithPath: filePath)
            let data = try! Data(contentsOf: url)
            let model = KaraokeView.parseLyricData(data: data)!
            self.lyricModel = model
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
        } fail: { error in
            print("fect fail")
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
        /// drag正在进行的时候, 不会更新内部的progress, 这个时候设置一个last值，等到下一个定时时间到来的时候，把这个last的值-250后送入组建
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
        lineScoreView.showScoreView(score: score)
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
        incentiveView.reset()
        gradeView.reset()
        updateView(param: param)
        mccPreload()
    }
}