//
//  MccManager.swift
//  Demo
//
//  Created by ZYP on 2024/6/5.
//

import Foundation
import AgoraRtcKit
import RTMTokenBuilder

protocol MccManagerDelegate: NSObjectProtocol {
    func onJoinedChannel(_ manager: MccManager)
    func onPreloadMusic(_ manager: MccManager, songId: Int, errorMsg: String?)
    func onOpenMusic(_ manager: MccManager)
    func onPitch(_ manager: MccManager, pitch: Double)
    func onLyricResult(url: String)
}

class MccManager: NSObject {
    fileprivate let logTag = "MccManager"
    private var agoraKit: AgoraRtcEngineKit!
    private var mpk: AgoraMusicPlayerProtocol!
    weak var delegate: MccManagerDelegate?
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
        agoraKit?.disableAudio()
        mpk?.stop()
        mcc?.register(nil)
        agoraKit?.leaveChannel()
        if let mpk = mpk {
            agoraKit?.destroyMediaPlayer(mpk)
        }
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
    }
    
    func joinChannel() -> Bool { /** 目的：发布mic流、接收音频流 **/
        guard !Config.rtcAppId.isEmpty, !Config.rtcCertificate.isEmpty else {
            Log.errorText(text: "RTC App ID or certificate is missing", tag: logTag)
            return false
        }
        let token = TokenBuilder.rtcToken2(Config.rtcAppId,
                                            appCertificate: Config.rtcCertificate,
                                            uid: Int32(Config.hostUid),
                                            channelName: Config.channelId)
        guard !token.isEmpty else {
            Log.errorText(text: "RTC token generation failed", tag: logTag)
            return false
        }
        agoraKit.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        agoraKit.enableAudio()
        agoraKit.setClientRole(.broadcaster)
        let ret = agoraKit.joinChannel(byToken: token,
                                       channelId: Config.channelId,
                                       uid: Config.hostUid,
                                       mediaOptions: option)
        print("joinChannel ret \(ret)")
        return ret == 0
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
    
    func initMCC() -> Bool {
        guard !Config.mccAppId.isEmpty, !Config.mccCertificate.isEmpty else {
            Log.errorText(text: "MCC App ID or certificate is missing", tag: logTag)
            return false
        }
        let token = TokenBuilder.buildRtmToken2(Config.mccAppId,
                                                appCertificate: Config.mccCertificate,
                                                userUuid: "\(Config.mccUid)")
        guard !token.isEmpty else {
            Log.errorText(text: "MCC token generation failed", tag: logTag)
            return false
        }
        let config = AgoraMusicContentCenterConfig()
        config.rtcEngine = agoraKit
        config.mccUid = Config.mccUid
        config.token = token
        config.appId = Config.mccAppId
        if let mccDomain = Config.mccDomain {
            config.mccDomain = mccDomain
        }
        guard let center = AgoraMusicContentCenter.sharedContentCenter(config: config) else {
            Log.errorText(text: "MCC initialization failed", tag: logTag)
            return false
        }
        mcc = center
        guard let player = center.createMusicPlayer(delegate: self) else {
            Log.errorText(text: "MCC music player creation failed", tag: logTag)
            return false
        }
        mpk = player
        center.register(self)
        return true
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
        isPause = false
    }
    
    func stopMusic() {
        guard let mpk = mpk else { return }
        let ret = mpk.stop()
        if ret != 0 {
            Log.errorText(text: "stop error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "stop success", tag: logTag)
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

extension MccManager {
    private func logPitchTime(pitch: CFAbsoluteTime) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let gap = currentTime - lastPitchTime
        lastPitchTime = currentTime
        if gap > 50 {
            Log.errorText(text: "gap:[\(gap.keep3)] \(pitch)")
        }
    }
}

extension MccManager: AgoraRtcEngineDelegate {
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
        if isPause {
            return
        }
        if let pitch = speakers.last?.voicePitch {
            if enableLogPitchTime { logPitchTime(pitch: pitch) }
            delegate?.onPitch(self, pitch: pitch)
        }
    }
}

extension MccManager: AgoraMusicContentCenterEventDelegate {
    func onExtResponse(_ requestId: String, jsonOption: String, httpCode: Int, response: String) {}

    func onPreLoadEvent(_ requestId: String,
                        songCode: Int,
                        percent: Int,
                        lyricUrl: String?,
                        state status: AgoraMusicContentCenterPreloadStatus,
                        reason errorCode: AgoraMusicContentCenterStatusCode) {
        Log.debug(text: "onPreLoadEvent requestId:\(requestId) songCode:\(songCode) status:\(status) percent:\(percent) lyricUrl:\(lyricUrl ?? "nil") errorCode:\(errorCode)", tag: logTag)
        if status == .OK { /** preload 成功 **/
            Log.info(text: "preload ok", tag: logTag)
            invokeOnPreloadMusic(self, songId: songId, errorMsg: nil)
        }
        
        if status == .error {
            Log.errorText(text: "onPreLoadEvent percent:\(percent) status:\(status.rawValue) lyricUrl:\(lyricUrl ?? "null")", tag: logTag)
            if errorCode == .errorPermissionAndResource {
                Log.errorText(text: "歌曲下架")
            }
            invokeOnPreloadMusic(self, songId: songCode, errorMsg: "preload error")
        }
    }
    
    func onMusicChartsResult(_ requestId: String,
                             result: [AgoraMusicChartInfo],
                             reason errorCode: AgoraMusicContentCenterStatusCode) {}
    func onMusicCollectionResult(_ requestId: String,
                                 result: AgoraMusicCollection,
                                 reason errorCode: AgoraMusicContentCenterStatusCode) {}
    func onSongSimpleInfoResult(_ requestId: String,
                                songCode: Int,
                                simpleInfo: String?,
                                reason errorCode: AgoraMusicContentCenterStatusCode) {}
    func onLyricResult(_ requestId: String,
                       songCode: Int,
                       lyricUrl: String?,
                       reason errorCode: AgoraMusicContentCenterStatusCode) {
        Log.info(text: "onLyricResult requestId:\(requestId) songCode:\(songCode) lyricUrl:\(lyricUrl ?? "null") errorCode:\(errorCode)", tag: logTag)
        if errorCode == .OK, let url = lyricUrl {
            delegate?.onLyricResult(url: url)
        }
    }
}

extension MccManager: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, reason error: AgoraMediaPlayerReason) {
        if state == .openCompleted {
            Log.info(text: "openCompleted", tag: logTag)
            delegate?.onOpenMusic(self)
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo position: Int) {}
}

extension MccManager {
    func invokeOnPreloadMusic(_ manager: MccManager, songId: Int, errorMsg: String?) {
        if Thread.isMainThread {
            self.delegate?.onPreloadMusic(manager, songId: songId, errorMsg: errorMsg)
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.onPreloadMusic(manager, songId: songId, errorMsg: errorMsg)
        }
    }
}
