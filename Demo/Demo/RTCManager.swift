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
//    func RTCManagerDidDownloadFile(lyricData: Data, pitchData: Data)
    func RTCManagerDidUpdatePitch(pitch: Double)
}

protocol RTCManagerSongListDelegate: NSObjectProtocol {
    func RTCManagerDidRecvSearch(result: AgoraMusicCollection)
}

class RTCManager: NSObject {
    var agoraKit: AgoraRtcEngineKit!
    var mediaPlayer: AgoraRtcMediaPlayerProtocol!
    weak var delegate: RTCManagerDelegate?
    weak var songListDelegate: RTCManagerSongListDelegate?
    var mcc: AgoraMusicContentCenter!
    var mpk: AgoraMusicPlayerProtocol!
    var song: MainTestVC.Item!
    var openCompleted = false
    var getLrcCompleted = false
    var streamId: Int = 0
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
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
    
    func joinChannel() {
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
    
    /**
     1.Preload -> Open
     2.GetLrc
     3.Play
     **/
    func loadMusic(song: MainTestVC.Item, getLyrics: Bool) {
        self.song = song
        openCompleted = false
        getLrcCompleted = false
        mpk.stop()
        mccPreload()
        if getLyrics { mccGetLrc() }
    }
    
    func search(keyWord: String, page: Int) {
        mcc.searchMusic(keyWord: keyWord,
                        page: page,
                        pageSize: 50,
                        jsonOption: nil)
    }
    
    func getPosition() -> Int {
        if getLrcCompleted, openCompleted {
            return mpk.getPosition()
        }
        return 0
    }
    
    func seek(time: Int) {
        if getLrcCompleted, openCompleted, mpk.getPlayerState() == .playing {
            mpk.seek(toPosition: time)
        }
    }
    
    func pause() {
        if getLrcCompleted, openCompleted {
            if mpk.getPlayerState() == .playing {
                mpk.pause()
                return
            }
            if mpk.getPlayerState() == .paused {
                mpk.resume()
                return
            }
        }
    }
    
    func stop() {
        if getLrcCompleted, openCompleted {
            mpk.stop()
        }
    }
    
    func sendData(data: Data) {
        if streamId > 0 {
            agoraKit.sendStreamMessage(streamId, data: data)
        }
    }
    
    func destory() {
        agoraKit.leaveChannel()
        agoraKit.disableAudio()
        mpk.stop()
        mcc.register(nil)
        agoraKit.destroyMediaPlayer(mpk)
    }
    
    private func mccPreload() {
        mcc.preload(songCode: song.code)
        invokeRTCManagerDidOccurEvent(event: "preload success")
    }
    
    private func mccOpen() {
        let ret = mpk.openMedia(songCode: song.code, startPos: 0)
        if ret != 0 {
            invokeRTCManagerDidOccurEvent(event: "open error \(ret)")
            return
        }
        invokeRTCManagerDidOccurEvent(event: "open success")
    }
    
    private func mccPlay() {
        let ret = mpk.play()
        if ret != 0 {
            invokeRTCManagerDidOccurEvent(event: "play error \(ret)")
            return
        }
        invokeRTCManagerDidOccurEvent(event: "play success")
    }
    
    private func mccGetLrc() {
        let requestId = mcc.getLyric(songCode: song.code, lyricType: song.lyricType)
        invokeRTCManagerDidOccurEvent(event: "getlrc success requestId:\(requestId)")
    }
    
    private func createDataStream() {
        let config = AgoraDataStreamConfig()
        config.syncWithAudio = false
        config.ordered = false
        let ret = agoraKit.createDataStream(&streamId, config: config)
        invokeRTCManagerDidOccurEvent(event: "createDataStream ret \(ret)")
    }
    
    func play() {
        mccPlay()
    }
}

extension RTCManager: AgoraRtcEngineDelegate, AgoraRtcMediaPlayerDelegate, AgoraMusicContentCenterEventDelegate {
    
    func onMusicChartsResult(_ requestId: String,
                             result: [AgoraMusicChartInfo],
                             errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onMusicCollectionResult(_ requestId: String,
                                 result: AgoraMusicCollection,
                                 errorCode: AgoraMusicContentCenterStatusCode) {
        if errorCode == .OK {
            invokeRTCManagerDidRecvSearch(result: result)
        }
    }
    
    func onLyricResult(_ requestId: String,
                       songCode: Int,
                       lyricUrl: String?,
                       errorCode: AgoraMusicContentCenterStatusCode) {
        if errorCode == .OK {
            invokeRTCManagerDidOccurEvent(event: "onLyricResult success songCode:\(songCode)")
            invokeRTCManagerDidOccurEvent(event: "lrc: \(lyricUrl!)")
            invokeRTCManagerDidGetLyricUrl(lyricUrl: lyricUrl!)
            getLrcCompleted = true
            return
        }
        invokeRTCManagerDidOccurEvent(event: "onLyricResult errorCode:\(errorCode.rawValue) requestId:\(requestId)")
    }
    
    func onSongSimpleInfoResult(_ requestId: String,
                                songCode: Int,
                                simpleInfo: String?,
                                errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onPreLoadEvent(_ requestId: String,
                        songCode: Int,
                        percent: Int,
                        lyricUrl: String?,
                        status: AgoraMusicContentCenterPreloadStatus,
                        errorCode: AgoraMusicContentCenterStatusCode) {
        invokeRTCManagerDidOccurEvent(event: "onPreLoadEvent status:\(status.rawValue) percent:\(percent)")
        if status == .OK { /** preload 成功 **/
            invokeRTCManagerDidOccurEvent(event: "onPreLoadEvent ok")
            mccOpen()
        }
        
        if status == .error {
            invokeRTCManagerDidOccurEvent(event: "onPreLoadEvent percent:\(percent) status:\(status.rawValue) lyricUrl:\(lyricUrl ?? "null")")
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            openCompleted = true
            invokeRTCManagerDidOccurEvent(event: "openCompleted")
            invokeRTCManagerDidOpenCompleted()
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError \(errorCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("didJoinedOfUid \(uid)")
        createDataStream()
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
        if Thread.isMainThread {
            delegate?.RTCManagerDidUpdatePitch(pitch: pitch)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.RTCManagerDidUpdatePitch(pitch: pitch)
        }
    }
    
    func invokeRTCManagerDidRecvSearch(result: AgoraMusicCollection) {
        if Thread.isMainThread {
            songListDelegate?.RTCManagerDidRecvSearch(result: result)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.songListDelegate?.RTCManagerDidRecvSearch(result: result)
        }
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
}
