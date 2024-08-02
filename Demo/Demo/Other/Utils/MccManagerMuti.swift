//
//  MccManagerMuti.swift
//  Demo
//
//  Created by ZYP on 2024/8/2.
//

import Foundation
import AgoraRtcKit
import RTMTokenBuilder

protocol MccManagerMutiDelegate: NSObjectProtocol {
    func onJoinedChannel(_ manager: MccManagerMuti)
    func onPreloadMusic(_ manager: MccManagerMuti, songId: Int, errorMsg: String?)
    func onOpenMusic(_ manager: MccManagerMuti)
    func onLyricResult(url: String)
    func onPitch(rawScoreData: AgoraRawScoreData)
    func onLineScore(lineScoreData: AgoraLineScoreData)
    func onLyricInfo(lyricInfo: AgoraLyricInfo?)
}

class MccManagerMuti: NSObject {
    fileprivate let logTag = "MccManagerMuti"
    private var agoraKit: AgoraRtcEngineKit!
    private var mpk: AgoraMusicPlayerProtocol!
    weak var delegate: MccManagerMutiDelegate?
    var mcc: AgoraMusicContentCenter!
    fileprivate var songId: Int = 0
    fileprivate var isPause = false
    /// 1是原唱，0是伴奏，默认1
    fileprivate var audioTrackIndex: Int32 = 1
    
    private var lastPitchTime: CFAbsoluteTime = 0
    
    /// only for test
    private var enableLogPitchTime = false
    /// only for test
    private var enableAudioDump = false
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        agoraKit.disableAudio()
        mpk.stop()
        mcc.register(nil)
        agoraKit.leaveChannel()
        agoraKit.destroyMediaPlayer(mpk)
    }
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        if enableAudioDump {
            agoraKit.setParameters("{\"rtc.debug.enable\": true}")
            agoraKit.setParameters("{\"che.audio.apm_dump\": true}")
        }
        agoraKit?.registerExtension(withVendor: "agora_audio_filters_aed", extension: "audio_event_detection_post", sourceType: .audioPlayout)
    }
    
    func joinChannel() { /** 目的：发布mic流、接收音频流 **/
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
    
    var streamId: Int = 0
    func createDataStream() {
        let config = AgoraDataStreamConfig()
        config.syncWithAudio = false
        config.ordered = false
        let ret = agoraKit.createDataStream(&streamId, config: config)
        print("createDataStream ret \(ret)")
    }
    
    func initMCC() {
        let token = TokenBuilder.buildRtmToken2(Config.mccAppId,
                                                appCertificate: Config.mccCertificate,
                                                userUuid: "\(Config.mccUid)")
        Log.info(text: "mcc token: \(token)", tag: logTag)
        let config = AgoraMusicContentCenterConfig()
        config.rtcEngine = agoraKit
        config.mccUid = Config.mccUid
        config.token = token
        config.appId = Config.mccAppId
        config.mccDomain = Config.mccDomain!
        config.scoreEventDelegate = self
        mcc = AgoraMusicContentCenter.sharedContentCenter(config: config)
        mcc.register(self)
        mcc.registerScoreEventDelegate(delegate: self)
        mpk = mcc.createMusicPlayer(delegate: self)
    }
    
    func preload(songCode: Int) {
        Log.info(text: "preload songCode:\(songCode)", tag: logTag)
        let _ = mcc.preload(songCode: songCode)
        self.songId = songCode
    }
    
    func getLrc(songCode: Int, lyricType: AgoraMusicContentCenter.LyricFileType) {
        let requestId = mcc.getLyric(songCode: songCode, lyricType: lyricType.rawValue)
        Log.debug(text: "mccGetLrc requestId:\(requestId)", tag: logTag)
    }
    
    func openMusic() {
        let ret = mpk.openMedia(songCode: songId, startPos: 0)
        if ret != 0 {
            Log.errorText(text: "openMedia error \(ret)", tag: logTag)
            return
        }
        Log.info(text: "openMedia success")
    }
    
    func playMusic() {
        let ret = mpk.play()
        if ret != 0 {
            Log.errorText(text: "play error \(ret)", tag: logTag)
            return
        }
        isPause = false
        Log.info(text: "play success")
    }
    
    func pauseMusic() {
        let ret = mpk.pause()
        if ret != 0 {
            Log.errorText(text: "pauseMusic error \(ret)", tag: logTag)
        }
        else {
            isPause = true
            Log.info(text: "pauseMusic success", tag: logTag)
        }
    }
    
    func resumeMusic() {
        let ret = mpk.resume()
        if ret != 0 {
            Log.errorText(text: "resumeMusic error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "resumeMusic success", tag: logTag)
        }
    }
    
    func stopMusic() {
        let ret = mpk.stop()
        if ret != 0 {
            Log.errorText(text: "stop error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "stop success", tag: logTag)
        }
    }
    
    func startScore() {
        var ret = mcc.setScoreLevel(level: .normal)
        if ret != 0 {
            Log.errorText(text: "setScoreLevel error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "setScoreLevel success", tag: logTag)
        }
        
        ret = mcc.startScore(songCode: songId)
        if ret != 0 {
            Log.errorText(text: "startScore error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "startScore success", tag: logTag)
        }
    }
    
    func seek(position: UInt) {
        Log.info(text: "seek \(Int(position))", tag: logTag)
        mpk.seek(toPosition: Int(position))
    }
    
    func getMPKCurrentPosition() -> Int {
        return mpk.getPosition()
    }
    
    func resversePlayMode() {
        let index: Int32 = audioTrackIndex == 1 ? 0 : 1
        let ret = mpk.selectAudioTrack(index)
        if ret == 0 {
            audioTrackIndex = index
            let text = index == 1 ? "原唱" : "伴唱"
            Log.info(text: "原唱伴奏切换：\(text)", tag: logTag)
        }
        else {
            Log.errorText(text: "selectAudioTrack error \(ret)", tag: logTag)
        }
    }
}

extension MccManagerMuti {
    private func logPitchTime(pitch: CFAbsoluteTime) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let gap = currentTime - lastPitchTime
        lastPitchTime = currentTime
        if gap > 50 {
            Log.errorText(text: "gap:[\(gap.keep3)] \(pitch)")
        }
    }
}

extension MccManagerMuti: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinChannel channel: String,
                   withUid uid: UInt,
                   elapsed: Int) {
        delegate?.onJoinedChannel(self)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        Log.errorText(text:"didOccurError \(errorCode)", tag: logTag)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        Log.info(text: "didJoinedOfUid \(uid)", tag: logTag)
        createDataStream()
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
    }
}

extension MccManagerMuti: AgoraMusicContentCenterEventDelegate {
    func onLyricInfo(_ requestId: String, songCode: Int, lyricInfo: AgoraLyricInfo?, errorCode: AgoraMusicContentCenterStatusCode) {
        if errorCode != .OK {
            Log.debug(text: "onLyricInfo requestId:\(requestId) songCode:\(songCode) errorCode:\(errorCode)", tag: logTag)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.onLyricInfo(lyricInfo: lyricInfo)
        }
    }
    
    func onPreLoadEvent(_ requestId: String,
                        songCode: Int,
                        percent: Int,
                        lyricUrl: String?,
                        status: AgoraMusicContentCenterPreloadStatus,
                        errorCode: AgoraMusicContentCenterStatusCode) {
        Log.debug(text: "onPreLoadEvent requestId:\(requestId) songCode:\(songCode) status:\(status) percent:\(percent) lyricUrl:\(lyricUrl ?? "nil") errorCode:\(errorCode)", tag: logTag)
        if status == .OK { /** preload 成功 **/
            Log.info(text: "preload ok", tag: logTag)
            delegate?.onPreloadMusic(self, songId: songCode, errorMsg: nil)
        }
        
        if status == .error {
            Log.errorText(text: "onPreLoadEvent percent:\(percent) status:\(status.rawValue) lyricUrl:\(lyricUrl ?? "null")", tag: logTag)
            if errorCode == .errorPermissionAndResource {
                Log.errorText(text: "歌曲下架")
            }
            delegate?.onPreloadMusic(self, songId: songCode, errorMsg: "preload error")
        }
    }
    
    func onMusicChartsResult(_ requestId: String,
                             result: [AgoraMusicChartInfo],
                             errorCode: AgoraMusicContentCenterStatusCode) {}
    func onMusicCollectionResult(_ requestId: String,
                                 result: AgoraMusicCollection,
                                 errorCode: AgoraMusicContentCenterStatusCode) {}
    func onSongSimpleInfoResult(_ requestId: String,
                                songCode: Int,
                                simpleInfo: String?,
                                errorCode: AgoraMusicContentCenterStatusCode) {}
    func onLyricResult(_ requestId: String,
                       songCode: Int,
                       lyricUrl: String?,
                       errorCode: AgoraMusicContentCenterStatusCode) {
        Log.info(text: "onLyricResult requestId:\(requestId) songCode:\(songCode) lyricUrl:\(lyricUrl ?? "null") errorCode:\(errorCode)", tag: logTag)
        if errorCode == .OK, let url = lyricUrl {
            delegate?.onLyricResult(url: url)
        }
    }
}

extension MccManagerMuti: AgoraMusicContentCenterScoreEventDelegate {
    func onPitch(_ songCode: Int, rawScoreData: AgoraRawScoreData) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.onPitch(rawScoreData: rawScoreData)
        }
    }
    
    func onLineScore(_ songCode: Int, lineScoreData: AgoraLineScoreData) {
        Log.debug(text: "onLineScore, pitchScore:\(lineScoreData.pitchScore), cumulativePitchScore:\(lineScoreData.cumulativePitchScore), energyScore:\(lineScoreData.energyScore)", tag: logTag)
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.onLineScore(lineScoreData: lineScoreData)
        }
    }
}

extension MccManagerMuti: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            Log.info(text: "openCompleted", tag: logTag)
            delegate?.onOpenMusic(self)
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo position: Int) {}
}
