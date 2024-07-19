//
//  MCCManager.swift
//  Demo
//
//  Created by ZYP on 2024/4/18.
//
import AgoraRtcKit
import RTMTokenBuilder
import AgoraMccExService

protocol MccManagerDelegateEx: NSObjectProtocol {
    func onMccExInitialize(_ manager: MccManagerEx)
    func onPreloadMusic(_ manager: MccManagerEx,
                        songId: Int,
                        lyricData: Data,
                        pitchData: Data,
                        percent: Int,
                        lyricOffset: Int,
                        songOffsetBegin: Int,
                        errMsg: String?)
    func onOpenMusic(_ manager: MccManagerEx)
    func onMccExScoreStart(_ manager: MccManagerEx)
    func onPitch(_ songCode: Int, data: AgoraRawScoreDataEx)
    func onLineScore(_ songCode: Int, value: AgoraLineScoreDataEx)
}

class MccManagerEx: NSObject {
    fileprivate let logTag = "MCCManagerEx"
    private var agoraKit: AgoraRtcEngineKit!
    private var mpkEx: AgoraMusicPlayerProtocolEx!
    weak var delegate: MccManagerDelegateEx?
    var mccEx: AgoraMusicContentCenterEx!
    private var playMode: AgoraMusicPlayModeEx = .accompany
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        agoraKit?.disableAudio()
        mccEx?.stopScore()
        mccEx?.destroyMusicPlayer(mpkEx)
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
    
    func initMccEx(pid: String, pKey: String, token: String, userId: String) {
        Log.info(text: "initMccEx", tag: logTag)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID.init().uuidString
        let pid = pid
        let pKey = pKey
        let token = token
        let userId = userId
        let vendorConfig = AgoraYSDVendorConfigure(appId: pid,
                                                   appKey: pKey,
                                                   token: token,
                                                   userId: userId,
                                                   deviceId: deviceId,
                                                   urlTokenExpireTime: 15*60,
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
        mccEx = AgoraMusicContentCenterEx.sharedInstance()
        mccEx?.initialize(config)
        mccEx.setScoreLevel(.level1)
    }
    
    func createMusicPlayer() {
        Log.info(text: "createMusicPlayer", tag: logTag)
        mpkEx = mccEx.createMusicPlayer(with: self)
        if mpkEx == nil {
            Log.errorText(text: "mpk is nil", tag: logTag)
            fatalError()
        }
    }
    
    func preload(songId: Int) {
        Log.info(text: "preload \(songId)", tag: logTag)
        let ret = mccEx.preload(songId)
        if ret == nil {
            Log.errorText(text: "preload error", tag: logTag)
        }
        else {
            Log.info(text: "preload invoke success", tag: logTag)
        }
    }
    
    func getInternalSongCode(songId: Int) -> Int {
        guard let mcc = mccEx else { return 0 }
        let musicId = "\(songId)"
        let jsonOption = "{\"format\":{\"highPart\":1}}"
        let songCode = mcc.getInternalSongCode(musicId, jsonOption: jsonOption)
        Log.info(text: "getInternalSongCode songId:\(songId) -> \(songCode)", tag: logTag)
        return songCode
    }
    
    func open(songId: Int) {
        let ret = mpkEx.openMedia(songCode: songId, startPos: 0)
        if ret != 0 {
            Log.errorText(text: "openMedia error \(ret)", tag: logTag)
            return
        }
        Log.info(text: "open success", tag: logTag)
    }
    
    func playMusic() {
        let ret = mpkEx.play()
        if ret != 0 {
            Log.errorText(text: "playMusic error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "playMusic success", tag: logTag)
        }
    }
    
    func pauseMusic() {
        let ret = mpkEx.pause()
        if ret != 0 {
            Log.errorText(text: "pauseMusic error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "pauseMusic success", tag: logTag)
        }
    }
    
    func resumeMusic() {
        let ret = mpkEx.resume()
        if ret != 0 {
            Log.errorText(text: "resumeMusic error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "resumeMusic success", tag: logTag)
        }
    }
    
    func stopMusic() {
        let ret = mpkEx.stop()
        if ret != 0 {
            Log.errorText(text: "stop error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "stop success", tag: logTag)
        }
    }
    /// 跳过前奏
    func seek(position: UInt) {
        Log.info(text: "seek \(Int(position))", tag: logTag)
        mpkEx.seek(toPosition: Int(position))
    }
    
    func startScore(songId: Int) {
        let ret = mccEx.startScore(songId)
        if ret != 0 {
            Log.errorText(text: "startScore error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "startScore success", tag: logTag)
        }
    }
    
    func pauseScore() {
        mccEx.pauseScore()
        Log.info(text: "pauseScore success", tag: logTag)
    }
    
    func resumeScore() {
        mccEx.resumeScore()
        Log.info(text: "resumeScore success", tag: logTag)
    }
    
    func setScoreLevel(level: AgoraYSDScoreHardLevel) {
        mccEx.setScoreLevel(level)
        Log.info(text: "setScoreLevel \(level.rawValue)", tag: logTag)
    }
    
    func getMPKCurrentPosition() -> Int {
        return mpkEx.getPosition()
    }
    
    func resversePlayMode() {
        let mode: AgoraMusicPlayModeEx = playMode == .accompany ? .original : .accompany
        
        let ret = mpkEx.setPlayMode(mode: mode)
        if ret != 0 {
            Log.errorText(text: "setPlayMode error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "setPlayMode \(mode == .original ? "original" : "accompany") success", tag: logTag)
            playMode = mode
        }
    }
}

extension MccManagerEx: AgoraRtcEngineDelegate {
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

// MARK: - AgoraMusicContentCenterEventDelegate
extension MccManagerEx: AgoraMusicContentCenterEventDelegate {
    func onMusicChartsResult(_ requestId: String,
                             result: [AgoraMusicChartInfo],
                             errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onMusicCollectionResult(_ requestId: String,
                                 result: AgoraMusicCollection,
                                 errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onLyricResult(_ requestId: String,
                       songCode: Int,
                       lyricUrl: String?,
                       errorCode: AgoraMusicContentCenterStatusCode) {
        
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
        
    }
}

// MARK: - AgoraMusicContentCenterExEventDelegate
extension MccManagerEx: AgoraMusicContentCenterExEventDelegate {
    func onPreLoadEvent(_ requestId: String, songCode: Int, percent: Int, lyricPath: String?, pitchPath: String?, songOffsetBegin: Int, songOffsetEnd: Int, lyricOffset: Int, state: AgoraMusicContentCenterExState, reason: AgoraMusicContentCenterExStateReason) {
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
            let errMsg = state != .preloadOK ? "preload state:\(state.rawValue) error:\(reason.rawValue)" : nil
            delegate?.onPreloadMusic(self,
                                     songId: songCode,
                                     lyricData: lyricData,
                                     pitchData: pitchData,
                                     percent: percent,
                                     lyricOffset: lyricOffset,
                                     songOffsetBegin: songOffsetBegin,
                                     errMsg: errMsg)
        }
    }
    
    func onLyricResult(_ requestId: String, songCode: Int, lyricPath: String?, songOffsetBegin: Int, songOffsetEnd: Int, lyricOffset: Int, reason: AgoraMusicContentCenterExStateReason) {
        Log.info(text: "[MccEx]: onLyricResult: \(requestId) songCode: \(songCode) lyricPath: \(lyricPath ?? "") reason: \(reason.rawValue)", tag: self.logTag)
    }
    
    func onInitializeResult(_ state: AgoraMusicContentCenterExState,
                            reason: AgoraMusicContentCenterExStateReason) {
        Log.info(text: "[MccEx]: onInitializeResult: \(state.rawValue) reason: \(reason.rawValue)", tag: self.logTag)
        if state == .initialized, reason == .OK {
            delegate?.onMccExInitialize(self)
        }
    }
    
    func onStartScoreResult(_ songCode: Int, state: AgoraMusicContentCenterExState, reason: AgoraMusicContentCenterExStateReason) {
        Log.info(text: "[MccEx]: onStartScoreResult: \(songCode) state: \(state.description) reason: \(reason.description)", tag: self.logTag)
        delegate?.onMccExScoreStart(self)
    }
    
    func onPitchResult(_ requestId: String,
                       songCode: Int,
                       pitchPath: String?,
                       songOffsetBegin offsetBegin: Int,
                       songOffsetEnd offsetEnd: Int,
                       reason: AgoraMusicContentCenterExStateReason) {}
}

extension MccManagerEx: AgoraMusicContentCenterExScoreEventDelegate {
    func onPitch(_ songCode: Int, data: AgoraRawScoreDataEx) {
        Log.info(text: "[MccEx]: onPitch: \(songCode) progressInMs: \(data.progressInMs) speakerPitch: \(data.speakerPitch) pitchScore: \(data.pitchScore)", tag: self.logTag)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            delegate?.onPitch(songCode, data: data)
        }
    }
    
    func onLineScore(_ songCode: Int, value: AgoraLineScoreDataEx) {
        Log.info(text: "[MccEx>>>>]: onLineScore: \(songCode) progressInMs: \(value.progressInMs) performedLineIndex: \(value.performedLineIndex) linePitchScore:\(value.linePitchScore) performedTotalLines: \(value.performedTotalLines) cumulativeTotalLinePitchScores: \(value.cumulativeTotalLinePitchScores)", tag: self.logTag)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            delegate?.onLineScore(songCode, value: value)
        }
    }
}

extension MccManagerEx: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol,
                             didChangedTo state: AgoraMediaPlayerState,
                             error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            Log.info(text: "openCompleted", tag: logTag)
            delegate?.onOpenMusic(self)
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol,
                             didChangedTo position: Int) {}
}
