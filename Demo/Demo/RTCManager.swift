//
//  RTCManager.swift
//  Demo
//
//  Created by ZYP on 2024/4/18.
//
import AgoraRtcKit
import RTMTokenBuilder
import AgoraMccExService

protocol RTCManagerDelegate: NSObjectProtocol {
    func rtcManager(_ manager: RTCManager, didProloadMusicWithSongId: Int, lyricData: Data, pitchData: Data)
    func rtcManagerDidOpenMusic(_ manager: RTCManager)
    func rtcManagerDidInitializeMcc(_ manager: RTCManager)
    func onPitch(_ songCode: Int, data: AgoraRawScoreData)
    func onLineScore(_ songCode: Int, value: AgoraLineScoreData)
}

class RTCManager: NSObject {
    fileprivate let logTag = "RTCManager"
    private var agoraKit: AgoraRtcEngineKit!
    private var mpk: AgoraMusicPlayerProtocolEx!
    weak var delegate: RTCManagerDelegate?
    var fakeScoringMachine: BaseFakeScoringMachine?
    let useFakeScoringMachine: Bool
    var mccExService: AgoraMusicContentCenterEx!
    
    init(fakeScoringMachine: BaseFakeScoringMachine? = nil) {
        self.fakeScoringMachine = fakeScoringMachine
        useFakeScoringMachine = fakeScoringMachine != nil
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        agoraKit.disableAudio()
        mccExService.destroyMusicPlayer(mpk)
        AgoraMusicContentCenterEx.destroy()
        AgoraRtcEngineKit.destroy()
    }
    
    func initEngine() {
        Log.info(text: "initEngine", tag: logTag)
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit.registerExtension(withVendor: "agora_audio_filters_aed", extension: "audio_event_detection_post", sourceType: .audioPlayout)
    }
    
    func joinChannel() { /** 目的：发布mic流、接收音频流 **/
        Log.info(text: "joinChannel", tag: logTag)
        agoraKit.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        agoraKit.enableAudio()
        agoraKit.setClientRole(.broadcaster)
        let ret = agoraKit.joinChannel(byToken: nil,
                                       channelId: Config.channelId,
                                       uid: Config.hostUid,
                                       mediaOptions: option)
        Log.info(text: "joinChannel ret \(ret)", tag: logTag)
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel()
    }
    
    func initMccEx() {
        
    }
    
    func createMusicPlayer() {
        Log.info(text: "createMusicPlayer", tag: logTag)
        mpk = mccExService.createMusicPlayer(with: self)
        if mpk == nil {
            fatalError()
        }
        mpk.setPlayMode(mode: .original)
    }
    
    func preload(songId: Int) {
        Log.info(text: "getSongCode \(songId)", tag: logTag)
        let newSongId = getSongCode(songId: songId)
        
        Log.info(text: "preload \(newSongId)", tag: logTag)
        let ret = mccExService.preload(newSongId)
        if ret == nil {
            Log.errorText(text: "preload error", tag: logTag)
        }
        else {
            Log.info(text: "preload success", tag: logTag)
        }
    }
    
    func getSongCode(songId: Int) -> Int {
        guard let mcc = mccExService else { return 0 }
        let musicId = "\(songId)"
        let jsonOption = "{\"format\":{\"highPart\":0}}"
        let songCode = mcc.getInternalSongCode(musicId, jsonOption: jsonOption)
        return songCode
    }
    
    func open(songId: Int) {
        let newSongId = getSongCode(songId: songId)
        let ret = mpk.openMedia(songCode: newSongId, startPos: 0)
        if ret != 0 {
            Log.errorText(text: "openMedia error \(ret)", tag: logTag)
            return
        }
        Log.info(text: "open success", tag: logTag)
    }
    
    func playMusic() {
        let ret = mpk.play()
        if ret != 0 {
            Log.errorText(text: "playMusic error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "playMusic success", tag: logTag)
        }
    }
    
    func pauseMusic() {
        let ret = mpk.pause()
        if ret != 0 {
            Log.errorText(text: "pauseMusic error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "pauseMusic success", tag: logTag)
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
    /// 跳过前奏
    func skipMusicPrelude(preludeEndPosition: UInt) {
        mpk.seek(toPosition: Int(preludeEndPosition))
    }
    
    func startScore(songId: Int) {
        if useFakeScoringMachine {
            fakeScoringMachine?.startScore(songId: songId)
            return
        }
        
        let newSongId = getSongCode(songId: songId)
        
        let ret = mccExService.startScore(newSongId)
        if ret != 0 {
            Log.errorText(text: "startScore error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "startScore success", tag: logTag)
        }
    }
    
    func pauseScore() {
        if useFakeScoringMachine {
            fakeScoringMachine?.pauseScore()
            return
        }
        
        mccExService.pauseScore()
        Log.info(text: "pauseScore success", tag: logTag)
    }
    
    func resumeScore() {
        if useFakeScoringMachine {
            fakeScoringMachine?.resumeScore()
            return
        }
        
        mccExService.resumeScore()
        Log.info(text: "resumeScore success", tag: logTag)
    }
    
    func setScoreLevel(level: AgoraYSDScoreHardLevel) {
        mccExService.setScoreLevel(level)
        Log.info(text: "setScoreLevel \(level.rawValue)", tag: logTag)
    }
    
    func getMPKCurrentPosition() -> Int {
        return mpk.getPosition()
    }
}

extension RTCManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didOccurError errorCode: AgoraErrorCode) {
        Log.debug(text: "didOccurError \(errorCode)", tag: self.logTag)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinedOfUid uid: UInt,
                   elapsed: Int) {
        Log.debug(text: "didJoinedOfUid \(uid)", tag: self.logTag)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinChannel channel: String,
                   withUid uid: UInt,
                   elapsed: Int) {
        Log.debug(text: "didJoinChannel withUid \(uid)", tag: self.logTag)
    }
}

extension RTCManager: AgoraMusicContentCenterExEventDelegate {
    func onInitializeResult(_ state: AgoraMusicContentCenterExState,
                            reason: AgoraMusicContentCenterExStateReason) {
        Log.info(text: "[MccEx]: onInitializeResult: \(state.rawValue) reason: \(reason.rawValue)", tag: self.logTag)
        if state == .initialized, reason == .OK {
            delegate?.rtcManagerDidInitializeMcc(self)
        }
    }
    
    func onStartScoreResult(_ songCode: Int, state: AgoraMusicContentCenterExState, reason: AgoraMusicContentCenterExStateReason) {
        Log.info(text: "[MccEx]: onStartScoreResult: \(songCode) state: \(state.rawValue) reason: \(reason.rawValue)", tag: self.logTag)
    }
    
    func onPreLoadEvent(_ requestId: String,
                        songCode: Int,
                        percent: Int,
                        lyricPath: String?,
                        pitchPath: String?,
                        offsetBegin: Int,
                        offsetEnd: Int,
                        state: AgoraMusicContentCenterExState,
                        reason: AgoraMusicContentCenterExStateReason) {
        Log.info(text: "[MccEx]: onPreLoadEvent: \(requestId) songCode: \(songCode) percent: \(percent) lyricPath: \(lyricPath ?? "") pitchPath: \(pitchPath ?? "") state: \(state.rawValue) state: \(state.rawValue)", tag: self.logTag)
        
        if state == .preloading {
            Log.debug(text: "preloading \(percent)", tag: logTag)
        }
        if state == .preloadOK {
            Log.info(text: "preload success", tag: logTag)
            guard let lyricPath = lyricPath else {
                Log.errorText(text: "lyricPath is nil", tag: logTag)
                return
            }
            
            guard let pitchPath = pitchPath else {
                Log.errorText(text: "pitchPath is nil", tag: logTag)
                return
            }
            
            let lyricData = try! Data(contentsOf: URL(fileURLWithPath: lyricPath))
            let pitchData = try! Data(contentsOf: URL(fileURLWithPath: pitchPath))
            
            delegate?.rtcManager(self, didProloadMusicWithSongId: songCode, lyricData: lyricData, pitchData: pitchData)
        }
    }
    
    func onLyricResult(_ requestId: String, songCode: Int, lyricPath: String?, offsetBegin: Int, offsetEnd: Int, reason: AgoraMusicContentCenterExStateReason) {
        Log.info(text: "[MccEx]: onLyricResult: \(requestId) songCode: \(songCode) lyricPath: \(lyricPath ?? "") reason: \(reason.rawValue)", tag: self.logTag)
    }
    
    func onPitchResult(_ requestId: String,
                       songCode: Int,
                       pitchPath: String?,
                       offsetBegin: Int,
                       offsetEnd: Int,
                       reason: AgoraMusicContentCenterExStateReason) {
        
    }
}

extension RTCManager: AgoraMusicContentCenterExScoreEventDelegate {
    func onPitch(_ songCode: Int, data: AgoraRawScoreData) {
        Log.info(text: "[MccEx]: onPitch: \(songCode) progressInMs: \(data.progressInMs) speakerPitch: \(data.speakerPitch) pitchScore: \(data.pitchScore)", tag: self.logTag)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            delegate?.onPitch(songCode, data: data)
        }
    }
    
    func onLineScore(_ songCode: Int, value: AgoraLineScoreData) {
        Log.info(text: "[MccEx]: onLineScore: \(songCode) progressInMs: \(value.progressInMs) performedLineIndex: \(value.performedLineIndex) linePitchScore:\(value.linePitchScore) performedTotalLines: \(value.performedTotalLines) cumulativeTotalLinePitchScores: \(value.cumulativeTotalLinePitchScores)", tag: self.logTag)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            delegate?.onLineScore(songCode, value: value)
        }
    }
}

extension RTCManager: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol,
                             didChangedTo state: AgoraMediaPlayerState,
                             error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            Log.info(text: "openCompleted", tag: logTag)
            delegate?.rtcManagerDidOpenMusic(self)
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol,
                             didChangedTo position: Int) {}
}
