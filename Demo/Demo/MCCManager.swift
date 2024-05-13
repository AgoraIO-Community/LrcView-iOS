//
//  MCCManager.swift
//  Demo
//
//  Created by ZYP on 2024/4/18.
//
import AgoraRtcKit
import RTMTokenBuilder
import AgoraMccExService

protocol MCCManagerDelegate: NSObjectProtocol {
    func onMccExInitialize(_ manager: MCCManager)
    func onProloadMusic(_ manager: MCCManager, songId: Int, lyricData: Data, pitchData: Data)
    func onOpenMusic(_ manager: MCCManager)
    func onMccExScoreStart(_ manager: MCCManager)
    func onPitch(_ songCode: Int, data: AgoraRawScoreData)
    func onLineScore(_ songCode: Int, value: AgoraLineScoreData)
}

class MCCManager: NSObject {
    fileprivate let logTag = "MCCManager"
    private var agoraKit: AgoraRtcEngineKit!
    private var mpk: AgoraMusicPlayerProtocolEx!
    weak var delegate: MCCManagerDelegate?
    var mccExService: AgoraMusicContentCenterEx!
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        agoraKit.disableAudio()
        mccExService.destroyMusicPlayer(mpk)
        AgoraMusicContentCenterEx.destroy()
        AgoraRtcEngineKit.destroy()
    }
    
    func initRtcEngine() {
        Log.info(text: "initRtcEngine", tag: logTag)
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }
    
    func joinChannel() { /** 目的：发布mic流、接收音频流 **/
        Log.info(text: "joinChannel", tag: logTag)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        agoraKit.enableAudio()
        agoraKit.disableVideo()
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
        Log.info(text: "initMccEx", tag: logTag)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID.init().uuidString
        let pid = Config.pid
        let pKey = Config.pKey
        let token = Config.token
        let userId = Config.userId
        let vendorConfig = AgoraYSDVendorConfigure(appId: pid,
                                                   appKey: pKey,
                                                   token: token,
                                                   userId: userId,
                                                   deviceId: deviceId,
                                                   chargeMode: .once)
        let config = AgoraMusicContentCenterExConfiguration.init(rtcEngine: agoraKit,
                                                                 vendorConfigure: vendorConfig,
                                                                 enableLog: true,
                                                                 enableSaveLogToFile: true,
                                                                 logFilePath: "",
                                                                 maxCacheSize: 50,
                                                                 eventDelegate: self,
                                                                 scoreEventDelegate: self,
                                                                 audioFrameDelegate: nil)
        mccExService = AgoraMusicContentCenterEx.sharedInstance()
        mccExService?.initialize(config)
        mccExService.setScoreLevel(.level1)
    }
    
    func createMusicPlayer() {
        Log.info(text: "createMusicPlayer", tag: logTag)
        mpk = mccExService.createMusicPlayer(with: self)
        if mpk == nil {
            Log.errorText(text: "mpk is nil", tag: logTag)
            fatalError()
        }
    }
    
    func preload(songId: Int) {
        Log.info(text: "preload \(songId)", tag: logTag)
        let ret = mccExService.preload(songId)
        if ret == nil {
            Log.errorText(text: "preload error", tag: logTag)
        }
        else {
            Log.info(text: "preload invoke success", tag: logTag)
        }
    }
    
    func getInternalSongCode(songId: Int) -> Int {
        guard let mcc = mccExService else { return 0 }
        let musicId = "\(songId)"
        let jsonOption = "{\"format\":{\"highPart\":0}}"
        let songCode = mcc.getInternalSongCode(musicId, jsonOption: jsonOption)
        return songCode
    }
    
    func open(songId: Int) {
        let ret = mpk.openMedia(songCode: songId, startPos: 0)
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
        let ret = mccExService.startScore(songId)
        if ret != 0 {
            Log.errorText(text: "startScore error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "startScore success", tag: logTag)
        }
    }
    
    func pauseScore() {
        mccExService.pauseScore()
        Log.info(text: "pauseScore success", tag: logTag)
    }
    
    func resumeScore() {
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

extension MCCManager: AgoraRtcEngineDelegate {
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

extension MCCManager: AgoraMusicContentCenterExEventDelegate {
    func onInitializeResult(_ state: AgoraMusicContentCenterExState,
                            reason: AgoraMusicContentCenterExStateReason) {
        Log.info(text: "[MccEx]: onInitializeResult: \(state.rawValue) reason: \(reason.rawValue)", tag: self.logTag)
        if state == .initialized, reason == .OK {
            delegate?.onMccExInitialize(self)
        }
    }
    
    func onStartScoreResult(_ songCode: Int, state: AgoraMusicContentCenterExState, reason: AgoraMusicContentCenterExStateReason) {
        Log.info(text: "[MccEx]: onStartScoreResult: \(songCode) state: \(state.rawValue) reason: \(reason.rawValue)", tag: self.logTag)
        delegate?.onMccExScoreStart(self)
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
            delegate?.onProloadMusic(self, songId: songCode, lyricData: lyricData, pitchData: pitchData)
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
                       reason: AgoraMusicContentCenterExStateReason) {}
}

extension MCCManager: AgoraMusicContentCenterExScoreEventDelegate {
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

extension MCCManager: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol,
                             didChangedTo state: AgoraMediaPlayerState,
                             error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            mpk.setPlayMode(mode: .original)
            Log.info(text: "openCompleted", tag: logTag)
            delegate?.onOpenMusic(self)
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol,
                             didChangedTo position: Int) {}
}
