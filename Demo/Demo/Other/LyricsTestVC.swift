//
//  LyricsTestVC.swift
//  Demo
//
//  Created by ZYP on 2022/12/23.
//

import UIKit
import AgoraRtcKit
import RTMTokenBuilder
import AgoraLyricsScore
import ScoreEffectUI

class LyricsTestVC: UIViewController {
    let karaokeView = KaraokeView()
    let gradeView = GradeView()
    let incentiveView = IncentiveView()
    var agoraKit: AgoraRtcEngineKit!
    var token: String!
    var mcc: AgoraMusicContentCenter!
    var mpk: AgoraMusicPlayerProtocol!
    var songCode = 6599298157850480 /// 十年
    private var timer = GCDTimer()
    var cumulativeScore = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    func setupUI() {
        karaokeView.lyricsView.inactiveLineTextColor = .yellow
        karaokeView.lyricsView.activeLineUpcomingTextColor = .blue
        karaokeView.lyricsView.activeLinePlayedTextColor = .cyan
        karaokeView.lyricsView.inactiveLineFontSize = .systemFont(ofSize: 16)
        karaokeView.lyricsView.activeLineUpcomingFontSize = .systemFont(ofSize: 23)
        karaokeView.lyricsView.draggable = true
        karaokeView.scoringView.viewHeight = 130
        karaokeView.scoringView.topSpaces = 50
        karaokeView.scoringView.localPitchCursorOffsetX = 5
        karaokeView.scoringView.localPitchCursorImage = UIImage(named: "t1")
//        karaokeView.scoringView.showDebugView = true
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
        view.backgroundColor = .black
        view.addSubview(karaokeView)
        view.addSubview(gradeView)
        view.addSubview(incentiveView)
        
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        gradeView.translatesAutoresizingMaskIntoConstraints = false
        incentiveView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
        
        gradeView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: 10).isActive = true
        gradeView.leftAnchor.constraint(equalTo: karaokeView.leftAnchor, constant: 15).isActive = true
        gradeView.rightAnchor.constraint(equalTo: karaokeView.rightAnchor, constant: -15).isActive = true
        gradeView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        incentiveView.centerYAnchor.constraint(equalTo: karaokeView.scoringView.centerYAnchor).isActive = true
        incentiveView.centerXAnchor.constraint(equalTo: karaokeView.centerXAnchor, constant: -10).isActive = true
    }
    
    func commonInit() {
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
        mcc.register(nil)
        mpk = mcc.createMusicPlayer(delegate: nil)
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
        mpk.seek(toPosition: 13 * 1000)
        
        timer.scheduledMillisecondsTimer(withName: "AVPlayerTestVC",
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
            
            self.karaokeView.setProgress(progress: self.last )
        }
    }
    
    func mccGetLrc() {
        let requestId = mcc.getLyric(songCode: songCode, lyricType: 0)
        print("== mccGetLrc requestId:\(requestId)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        mpk.seek(toPosition: 13000)
    }
}

extension LyricsTestVC: AgoraRtcEngineDelegate {
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

extension LyricsTestVC {
    func onMusicChartsResult(_ requestId: String, status: AgoraMusicContentCenterStatusCode, result: [AgoraMusicChartInfo]) {
        
    }
    
    func onMusicCollectionResult(_ requestId: String, status: AgoraMusicContentCenterStatusCode, result: AgoraMusicCollection) {
    }
    
    func onLyricResult(_ requestId: String, lyricUrl: String) {
        print("=== onLyricResult requestId:\(requestId) lyricUrl:\(lyricUrl)")
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "745012", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        let model = KaraokeView.parseLyricData(data: data)!
        DispatchQueue.main.async { [weak self] in
            self?.karaokeView.setLyricData(data: model)
            self?.gradeView.setTitle(title: "\(model.name) - \(model.singer)")
            self?.mccPlay()
            self?.mpk.seek(toPosition: 16000)
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


extension LyricsTestVC: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            print("=== openCompleted")
            mccGetLrc()
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo position: Int) {
//        DispatchQueue.main.async { [weak self] in
//            self?.karaokeView.setProgress(progress: position)
//        }
    }
}

extension LyricsTestVC: KaraokeDelegate {
    func onKaraokeView(view: KaraokeView, didDragTo position: Int) {
        mpk.seek(toPosition: position)
    }
    
    func onKaraokeView(view: KaraokeView,
                       didFinishLineWith model: LyricLineModel,
                       score: Int,
                       lineIndex: Int,
                       lineCount: Int) {
        cumulativeScore += score
        gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: lineCount * 100)
        incentiveView.show(score: score)
    }
}
