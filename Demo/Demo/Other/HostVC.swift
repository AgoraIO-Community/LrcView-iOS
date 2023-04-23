//
//  HostVC.swift
//  Demo
//
//  Created by ZYP on 2023/3/22.
//

import AgoraRtcKit
import AgoraLyricsScore
import ScoreEffectUI
import RTMTokenBuilder

class HostVC: UIViewController {
    var agoraKit: AgoraRtcEngineKit!
    let ktvView = KTVView()
    var song = MainTestVC.Item(code: 6625526605291650, isXML: true)
    var mcc: AgoraMusicContentCenter!
    var mpk: AgoraMusicPlayerProtocol!
    private var timer = GCDTimer()
    var isPause = false
    var streamId: Int = 0
    var packageNum: UInt64 = 0
    var token: String!
    var lyricModel: LyricModel!
    var lyricUrl: String?
    var cumulativeScore = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        view.addSubview(ktvView)
        ktvView.translatesAutoresizingMaskIntoConstraints = false
        ktvView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        ktvView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        ktvView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        ktvView.heightAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    func commonInit() {
        ktvView.karaokeView.delegate = self
        token = TokenBuilder.buildToken(Config.mccAppId,
                                        appCertificate: Config.mccCertificate,
                                        userUuid: "\(Config.mccUid)")
        initEngine()
        initMCC()
        joinChannel()
        
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
    
    func joinChannel() {
        agoraKit.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        option.publishMicrophoneTrack = true
        option.publishMediaPlayerId = Int(mpk.getMediaPlayerId())
        option.publishMediaPlayerAudioTrack = true
        let ret = agoraKit.joinChannel(byToken: nil,
                                       channelId: Config.channelId,
                                       uid: Config.hostUid,
                                       mediaOptions: option)
        
        print("joinChannel ret \(ret)")
    }
    
    func mccPreload() {
        let ret = mcc.preload(songCode: song.code, jsonOption: nil)
        if ret != 0 {
            print("preload error \(ret)")
            return
        }
        print("== preload success")
    }
    
    func mccOpen() {
        let ret = mpk.openMedia(songCode: song.code, startPos: 0)
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
            if self.isPause {
                return
            }
            
            var current = self.last
            if time.truncatingRemainder(dividingBy: 1000) == 0 {
                current = self.mpk.getPosition()
                let url = self.lyricUrl ?? ""
                self.packageNum += 1
                let dict: [String : Any] = ["type": 0, "url": url, "time": current, "packageNum" : self.packageNum]
                let data = self.createData(dic: dict)
                self.sendData(data: data)
            }
            current += 20

            self.last = current
            var time = current
            if time > 250 { /** 进度提前250ms, 第一个句子的第一个字得到更好匹配 **/
                time -= 250
            }
            self.ktvView.karaokeView.setProgress(progress: current )
        }
    }
    
    func mccGetLrc() {
        let requestId = mcc.getLyric(songCode: song.code, lyricType: song.isXML ? 0 : 1)
        print("== mccGetLrc requestId:\(requestId)")
    }

    func createDataStream() {
        let config = AgoraDataStreamConfig()
        config.syncWithAudio = false
        config.ordered = false
        let ret = agoraKit.createDataStream(&streamId, config: config)
        print("createDataStream ret \(ret)")
    }
    
    func sendData(data: Data) {
        if streamId > 0 {
            let ret = agoraKit.sendStreamMessage(streamId, data: data)
            print("sendStreamMessage \(ret)")
        }
    }
    
    func createData(dic: [String : Any]) -> Data {
        let data = try! JSONSerialization.data(withJSONObject: dic, options: [])
        return data
    }
}

extension HostVC: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError \(errorCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("didJoinedOfUid \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("didJoinChannel withUid \(uid)")
        createDataStream()
        mccPreload()
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        if isPause {
            return
        }
        if let pitch = speakers.last?.voicePitch {
            self.packageNum += 1
            let dict: [String : Any] = ["type": 1, "pitch": pitch, "packageNum" : self.packageNum]
            let data = self.createData(dic: dict)
            sendData(data: data)
            ktvView.karaokeView.setPitch(pitch: pitch)
        }
    }
}

extension HostVC: AgoraMusicContentCenterEventDelegate {
    func onMusicChartsResult(_ requestId: String, result: [AgoraMusicChartInfo], errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onMusicCollectionResult(_ requestId: String, result: AgoraMusicCollection, errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onLyricResult(_ requestId: String, songCode: Int, lyricUrl: String?, errorCode: AgoraMusicContentCenterStatusCode) {
        print("=== onLyricResult requestId:\(requestId) lyricUrl:\(lyricUrl!)")
        self.lyricUrl = lyricUrl!
        if lyricUrl!.isEmpty { /** 网络偶问题导致的为空 **/
            DispatchQueue.main.async { [weak self] in
                self?.title = "无歌词地址"
            }
            return
        }
        else {
            DispatchQueue.main.async { [weak self] in
                self?.title = nil
            }
        }
        FileCache.fect(urlString: lyricUrl!) { progress in

        } completion: { filePath in
            let url = URL(fileURLWithPath: filePath)
            let data = try! Data(contentsOf: url)
            let model = KaraokeView.parseLyricData(data: data)!
            self.lyricModel = model
            self.ktvView.karaokeView.setLyricData(data: model)
            self.ktvView.gradeView.setTitle(title: "\(model.name) - \(model.singer)")
            self.mccPlay()
            /// auto skip
            let toPosition = max(model.preludeEndPosition - 2000, 0)
            self.mpk.seek(toPosition: toPosition)
        } fail: { error in
            print("fect fail")
        }
    }
    
    func onSongSimpleInfoResult(_ requestId: String, songCode: Int, simpleInfo: String?, errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onPreLoadEvent(_ requestId: String, songCode: Int, percent: Int, lyricUrl: String?, status: AgoraMusicContentCenterPreloadStatus, errorCode: AgoraMusicContentCenterStatusCode) {
        print("== onPreLoadEvent \(status.rawValue) msg: \(errorCode)")
        if status == .OK { /** preload 成功 **/
            print("== preload ok")
            mccOpen()
        }
        
        if status == .error {
            print("onPreLoadEvent percent:\(percent) status:\(status.rawValue) msg:\(errorCode) lyricUrl:\(lyricUrl!)")
        }
    }
}


extension HostVC: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            print("=== openCompleted")
            mccGetLrc()
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo position: Int) {}
}


extension HostVC: KaraokeDelegate {
    func onKaraokeView(view: KaraokeView, didFinishLineWith model: LyricLineModel, score: Int, cumulativeScore: Int, lineIndex: Int, lineCount: Int) {
        ktvView.lineScoreView.showScoreView(score: score)
        self.cumulativeScore = cumulativeScore
        ktvView.gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: lineCount * 100)
        ktvView.incentiveView.show(score: score)
    }
}
