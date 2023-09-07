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
    func RTCManagerDidChangedTo(position: Int)
}

class RTCManager: NSObject {
    var agoraKit: AgoraRtcEngineKit!
    var mediaPlayer: AgoraRtcMediaPlayerProtocol!
    weak var delegate: RTCManagerDelegate?
    var mcc: AgoraMusicContentCenter!
    var mpk: AgoraMusicPlayerProtocol!
    var openCompleted = false
    var isRecord = false
    var pcmData = Data()
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit.setParameters("{\"che.audio.aiaec.working_mode\":1}")
        agoraKit.setParameters("{\"che.audio.aiaec.postprocessing_strategy\":1}")
        agoraKit.setParameters("{\"che.audio.apm_dump\":true}")
        agoraKit.setAudioFrameDelegate(self)
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
    
    public func startRecord() {
        pcmData = Data()
        isRecord = true
    }
    
    public func stopRecord() -> Data {
        isRecord = false
        let result = pcmData
        pcmData = Data()
        return result
    }
    
    public func getPcmData() -> Data {
        return pcmData
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
//            play()
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
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {}
    
    
}

// MARK: - AudioFrameDelegate

extension RTCManager: AgoraAudioFrameDelegate {
    func onEarMonitoringAudioFrame(_ frame: AgoraAudioFrame) -> Bool {
        true
    }
    
    func getEarMonitoringAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams ()
        params.sampleRate = 16000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 480
        return params
    }
    
    func getPlaybackAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams ()
        params.sampleRate = 16000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 480
        return params
    }
    
    func getRecordAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams ()
        params.sampleRate = 16000
        params.channel = 1
        params.mode = .readOnly
        params.samplesPerCall = 480
        return params
    }
    
    func onRecordAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        if isRecord, let buffer = frame.buffer  {
            let count = frame.channels * frame.bytesPerSample * frame.samplesPerChannel
            let data = Data(bytes: buffer, count: count)
            pcmData.append(data)
            
            /// 每秒钟产生的字节数
            let sec = 20
            let bytesPerSec = frame.samplesPerSec * frame.bytesPerSample * frame.channels
            /// 总字节数
            let totalBytes = bytesPerSec * sec
            if pcmData.count > totalBytes {
                pcmData = pcmData[pcmData.count-totalBytes..<pcmData.count]
            }
        }
        return true
    }
    
    func getObservedAudioFramePosition() -> AgoraAudioFramePosition {
        return .record
    }
    

    
    func onPlaybackAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        return true
    }
    
    func onMixedAudioFrame(_ frame: AgoraAudioFrame, channelId: String) -> Bool {
        return true
    }
    
    func getMixedAudioParams() -> AgoraAudioParams {
        let params = AgoraAudioParams ()
        params.sampleRate = 16000
        params.channel = 1
        params.mode = .readWrite
        params.samplesPerCall = 480
        return params
    }
    
    func onPlaybackAudioFrame(beforeMixing frame: AgoraAudioFrame, channelId: String, uid: UInt) -> Bool {
        
        return true
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
