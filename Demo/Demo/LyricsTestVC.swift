//
//  LyricsTestVC.swift
//  Demo
//
//  Created by ZYP on 2022/12/23.
//

import UIKit
import AgoraRtcKit
import TokenBuilder
import AgoraLyricsScore

class LyricsTestVC: UIViewController {
    let karaokeView = KaraokeView()
    var agoraKit: AgoraRtcEngineKit!
    var token: String!
    var mcc: AgoraMusicContentCenter!
    var mpk: AgoraMusicPlayerProtocol!
    var songCode = 6599298157850480 /// 十年
    private var timer = GCDTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        view.addSubview(karaokeView)
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    func commonInit() {
        token = TokenBuilder.buildToken(Config.mccAppId,
                                        appCertificate: Config.mccCertificate,
                                        userUuid: "\(Config.mccUid)")
        initEngine()
        initMCC()
        mccPreload()
    }
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
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
            let currentTime = self.mpk.getPosition() + 10
            self.karaokeView.setProgress(progress: Int(currentTime) )
        }
    }
    
    func mccGetLrc() {
        let requestId = mcc.getLyric(songCode: songCode, lyricType: 0)
        print("== mccGetLrc requestId:\(requestId)")
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
            
            
        }
    }
}

extension LyricsTestVC: AgoraMusicContentCenterEventDelegate {
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
            self?.mccPlay()
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
        DispatchQueue.main.async { [weak self] in
            self?.karaokeView.setProgress(progress: position)
        }
    }
}


