//
//  RTCManager.swift
//  Demo
//
//  Created by ZYP on 2024/4/18.
//
import AgoraRtcKit
import RTMTokenBuilder

protocol RTCManagerDelegate: NSObjectProtocol {
    func rtcManager(_ manager: RTCManager, didProloadMusicWithSongId: Int)
    func rtcManagerDidOpenMusic(_ manager: RTCManager)
    func rtcManager(_ manager: RTCManager, didReceivePitch pitch: Double)
    func onPitch(_ songCode: Int, item: AgoraRawScoreData)
    func onLineScore(_ songCode: Int, value: AgoraCumulativeScoreData)
    func onCumulativeScore(_ songCode: Int, value: AgoraCumulativeScoreData)
    func onLyricInfo(_ songCode: Int, lyricInfo: AgoraLyricInfo)
}

class RTCManager: NSObject {
    
    
    private var agoraKit: AgoraRtcEngineKit!
    private var mcc: AgoraMusicContentCenter!
    private var mpk: AgoraMusicPlayerProtocol!
    weak var delegate: RTCManagerDelegate?
    var fakeScoringMachine: BaseFakeScoringMachine?
    let useFakeScoringMachine: Bool
    var lyricInfo: AgoraLyricInfo?
    
    init(fakeScoringMachine: BaseFakeScoringMachine? = nil) {
        self.fakeScoringMachine = fakeScoringMachine
        useFakeScoringMachine = fakeScoringMachine != nil
    }
    
    deinit {
        agoraKit.disableAudio()
        mcc.register(nil)
        agoraKit.destroyMediaPlayer(mpk)
        AgoraRtcEngineKit.destroy()
    }
    
    func initEngine() {
        print("== initEngine")
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
    
    func leaveChannel() {
        agoraKit.leaveChannel()
    }
    
    func initMCC() {
        print("== initMCC")
        let token = TokenBuilder.buildToken(Config.mccAppId,
                                            appCertificate: Config.mccCertificate,
                                            userUuid: "\(Config.mccUid)")
        let config = AgoraMusicContentCenterConfig()
        config.rtcEngine = agoraKit
        config.mccUid = Config.mccUid
        config.token = token
        config.appId = Config.mccAppId
        config.mccDomain = "api-test.agora.io"
        mcc = AgoraMusicContentCenter.sharedContentCenter(config: config)
        mcc.register(self)
        mcc.registerScoreEventDelegate(delegate: self)
    }
    
    func createMusicPlayer() {
        print("== createMusicPlayer")
        mpk = mcc.createMusicPlayer(delegate: self)
    }
    
    func preload(songId: Int) {
        let _ = mcc.preload(songCode: songId)
        print("== preload \(songId)")
    }
    
    func open(songId: Int) {
        let ret = mpk.openMedia(songCode: songId, startPos: 0)
        if ret != 0 {
            print("openMedia error \(ret)")
            return
        }
        print("== openMedia success")
    }
    
    func playMusic() {
        let ret = mpk.play()
        if ret != 0 {
            print("play error \(ret)")
            return
        }
        print("== play success")
    }
    
    func pauseMusic() {
        let ret = mpk.pause()
        if ret != 0 {
            print("pause error \(ret)")
            return
        }
        print("== pause success")
    }
    
    func stopMusic() {
        let ret = mpk.stop()
        if ret != 0 {
            print("stop error \(ret)")
            return
        }
        print("== stop success")
    }
    /// 跳过前奏
    func skipMusicPrelude() {
        guard let preludeEndPosition = lyricInfo?.preludeEndPosition else {
            return
        }
        mpk.seek(toPosition: preludeEndPosition)
    }
    
    func getLyricInfo(songId: Int) -> AgoraLyricInfo {
        let info = mcc.getLyricInfo(songCode: songId)
        lyricInfo = info
        return info
    }
    
    func startScore(songId: Int) {
        if useFakeScoringMachine {
            fakeScoringMachine?.startScore(songId: songId)
            return
        }
        
        let ret = mcc.startScore(songCode: songId)
        if ret != 0 {
            print("== startScore error \(ret)")
            return
        }
        else {
            print("== startScore success")
        }
    }
    func pauseScore() {
        if useFakeScoringMachine {
            fakeScoringMachine?.pauseScore()
            return
        }
        
        mcc.pauseScore()
    }
    
    func resumeScore() {
        if useFakeScoringMachine {
            fakeScoringMachine?.resumeScore()
            return
        }
        
        mcc.resumeScore()
    }
    
    func setScoreLevel(level: Int) {
        if useFakeScoringMachine {
            fakeScoringMachine?.setScoreLevel(level: level)
            return
        }
        
        mcc.setScoreLevel(level: .easy)
    }
    
    func getMPKCurrentPosition() -> Int {
        return mpk.getPosition()
    }
}

extension RTCManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError \(errorCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinedOfUid uid: UInt,
                   elapsed: Int) {
        print("didJoinedOfUid \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinChannel channel: String,
                   withUid uid: UInt,
                   elapsed: Int) {
        print("didJoinChannel withUid \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo],
                   totalVolume: Int) {
        if let pitch = speakers.last?.voicePitch {
            delegate?.rtcManager(self, didReceivePitch: pitch)
        }
    }
}

extension RTCManager: AgoraMusicContentCenterScoreEventDelegate {
    func onPitch(_ songCode: Int, item: AgoraRawScoreData) {
        print("== onPitch \(item.description)")
        delegate?.onPitch(songCode, item: item)
    }
    
    func onLineScore(_ songCode: Int, value: AgoraCumulativeScoreData) {
        print("== onLineScore \(value.description)")
        delegate?.onLineScore(songCode, value: value)
    }
    
    func onCumulativeScore(_ songCode: Int, value: AgoraCumulativeScoreData) {
        print("== onCumulativeScore \(value.description)")
        delegate?.onCumulativeScore(songCode, value: value)
    }
    
    func onLyricInfo(_ songCode: Int, lyricInfo: AgoraLyricInfo) {
        print("== onLyricInfo \(lyricInfo.description)")
        delegate?.onLyricInfo(songCode, lyricInfo: lyricInfo)
    }
}

extension RTCManager: AgoraMusicContentCenterEventDelegate {
    func onMusicChartsResult(_ requestId: String,
                             result: [AgoraMusicChartInfo],
                             errorCode: AgoraMusicContentCenterStatusCode) {}
    
    func onMusicCollectionResult(_ requestId: String,
                                 result: AgoraMusicCollection,
                                 errorCode: AgoraMusicContentCenterStatusCode) {}
    
    func onLyricResult(_ requestId: String,
                       songCode: Int,
                       lyricUrl: String?,
                       errorCode: AgoraMusicContentCenterStatusCode) {}
    
    func onSongSimpleInfoResult(_ requestId: String,
                                songCode: Int,
                                simpleInfo: String?,
                                errorCode: AgoraMusicContentCenterStatusCode) {}
    
    func onPreLoadEvent(_ requestId: String,
                        songCode: Int,
                        percent: Int,
                        lyricUrl: String?,
                        status: AgoraMusicContentCenterPreloadStatus,
                        errorCode: AgoraMusicContentCenterStatusCode) {
        if errorCode != .OK {
            fatalError()
        }
        
        if status == .preloading {
            print("== preloading \(percent)")
        }
        if errorCode == .OK, status == .OK {
            print("== preload success")
            delegate?.rtcManager(self, didProloadMusicWithSongId: songCode)
        }
    }
}

extension RTCManager: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol,
                             didChangedTo state: AgoraMediaPlayerState,
                             error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            print("=== openCompleted")
            delegate?.rtcManagerDidOpenMusic(self)
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol,
                             didChangedTo position: Int) {}
}
 
