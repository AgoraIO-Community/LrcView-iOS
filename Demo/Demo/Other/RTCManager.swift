//
//  RTCManager.swift
//  Demo
//
//  Created by ZYP on 2023/7/3.
//

import AgoraRtcKit
import RTMTokenBuilder

protocol RTCManagerDelegate: NSObjectProtocol {
    func RTCManagerDidOccurEvent(event: String)
    func RTCManagerDidGetLyricUrl(lyricUrl: String)
    func RTCManagerDidOpenCompleted()
    func RTCManagerDidUpdatePitch(pitch: Double)
    func RTCManagerDidChangedTo(position: Int)
}

class RTCManager: NSObject {
    var agoraKit: AgoraRtcEngineKit!
    var mediaPlayer: AgoraRtcMediaPlayerProtocol!
    weak var delegate: RTCManagerDelegate?
    var mcc: AgoraMusicContentCenter!
    var mpk: AgoraMusicPlayerProtocol!
    var openCompleted = false
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit.setParameters("{\"che.audio.aiaec.working_mode\":1}")
        agoraKit.setParameters("{\"che.audio.aiaec.postprocessing_strategy\":1}")
        agoraKit.setParameters("{\"che.audio.apm_dump\":true}")
    }
    
    func initMCC() {
        let token = TokenBuilder.buildToken(Config.mccAppId,
                                            appCertificate: Config.mccCertificate,
                                            userUuid: "\(Config.mccUid)")
        let config = AgoraMusicContentCenterConfig()
        config.rtcEngine = agoraKit
        config.mccUid = Config.mccUid
        config.token = token
        config.appId = Config.mccAppId
        mcc = AgoraMusicContentCenter.sharedContentCenter(config: config)
        mcc.register(self)
        mpk = mcc.createMusicPlayer(delegate: self)
    }
    
    deinit {
        print("RTCManager deinit")
    }
    
    func joinChannel() {
        agoraKit.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        agoraKit.enableAudio()
        agoraKit.enableLocalAudio(false)
        agoraKit.setClientRole(.broadcaster)
        let ret = agoraKit.joinChannel(byToken: nil,
                                       channelId: Config.channelId,
                                       uid: Config.hostUid,
                                       mediaOptions: option)
        print("joinChannel ret \(ret)")
    }
    
    func destory() {
        agoraKit.leaveChannel()
        agoraKit.disableAudio()
        stop()
        mcc.register(nil)
        agoraKit.destroyMediaPlayer(mpk)
        AgoraMusicContentCenter.destroy()
    }
    
    public func open(url: String) {
        let ret = mpk.open(url, startPos: 0)
        if ret != 0 {
            print("open err \(ret)")
        }
    }
    
    public func play() {
        let ret = mpk.play()
        if ret != 0 {
            print("play err \(ret)")
        }
    }
    
    public func pause() {
        let ret = mpk.pause()
        if ret != 0 {
            print("pause err \(ret)")
        }
    }
    
    public func stop() {
        let state = mpk.getPlayerState()
        if state == .paused || state == .playing {
            let ret = mpk.stop()
            if ret != 0 {
                print("stop err \(ret)")
            }
        }
    }
    
    public func enableMic(enable: Bool) {
        agoraKit.enableLocalAudio(enable)
    }
}

extension RTCManager: AgoraRtcEngineDelegate, AgoraRtcMediaPlayerDelegate, AgoraMusicContentCenterEventDelegate {
    func onLyricResult(_ requestId: String, songCode: Int, lyricUrl: String?, errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onPreLoadEvent(_ requestId: String, songCode: Int, percent: Int, lyricUrl: String?, status: AgoraMusicContentCenterPreloadStatus, errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    
    func onMusicChartsResult(_ requestId: String,
                             result: [AgoraMusicChartInfo],
                             errorCode: AgoraMusicContentCenterStatusCode) {
    }
    
    func onMusicCollectionResult(_ requestId: String,
                                 result: AgoraMusicCollection,
                                 errorCode: AgoraMusicContentCenterStatusCode) {
    }
    
    func onSongSimpleInfoResult(_ requestId: String,
                                songCode: Int,
                                simpleInfo: String?,
                                errorCode: AgoraMusicContentCenterStatusCode) {
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            openCompleted = true
            play()
        }
    }
    
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
            invokeRTCManagerDidUpdatePitch(pitch: pitch)
        }
    }
}

extension RTCManager {
    func invokeRTCManagerDidOccurEvent(event: String) {
        if Thread.isMainThread {
            delegate?.RTCManagerDidOccurEvent(event: event)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.RTCManagerDidOccurEvent(event: event)
        }
    }
    
    func invokeRTCManagerDidGetLyricUrl(lyricUrl: String) {
        if Thread.isMainThread {
            delegate?.RTCManagerDidGetLyricUrl(lyricUrl: lyricUrl)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.RTCManagerDidGetLyricUrl(lyricUrl: lyricUrl)
        }
    }
    
    func invokeRTCManagerDidUpdatePitch(pitch: Double) {
        delegate?.RTCManagerDidUpdatePitch(pitch: pitch)
    }
    
    func invokeRTCManagerDidRecvSearch(result: AgoraMusicCollection) {
        
    }
    
    func invokeRTCManagerDidOpenCompleted() {
        if Thread.isMainThread {
            delegate?.RTCManagerDidOpenCompleted()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.RTCManagerDidOpenCompleted()
        }
    }
    
    func invokeRTCManagerDidChangedTo(position: Int) {
        if Thread.isMainThread {
            delegate?.RTCManagerDidChangedTo(position: position)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.RTCManagerDidChangedTo(position: position)
        }
    }
}
