//
//  MCCManager.swift
//  Demo
//
//  Created by ZYP on 2024/4/18.
//
import AgoraRtcKit
import RTMTokenBuilder

protocol MccManagerExDelegate: NSObjectProtocol {
    func onPreloadMusic(_ manager: MccManagerEx,
                        songId: Int,
                        percent: Int,
                        lyricData: Data,
                        pitchData: Data,
                        lyricOffset: Int,
                        songOffsetBegin: Int,
                        errorMsg: String?)
    func onOpenMusic(_ manager: MccManagerEx)
    func onLyricResult(url: String)
    func onMccExScoreStart(_ manager: MccManagerEx)
    func onPitch(_ manager: MccManagerEx, rawScoreData: AgoraRawScoreData)
    func onLineScore(_ songCode: Int, lineScoreData: AgoraLineScoreData)
}

class MccManagerEx: NSObject {
    fileprivate let logTag = "MccManagerEx"
    private var agoraKit: AgoraRtcEngineKit!
    private var mpk: AgoraMusicPlayerProtocol!
    weak var delegate: MccManagerExDelegate?
    var mcc: AgoraMusicContentCenter!
    fileprivate var songId: Int = 0
    fileprivate var isPause = false
    /// 1是原唱，0是伴奏，默认1
    fileprivate var audioTrackIndex: Int32 = 0
    private var lastPitchTime: CFAbsoluteTime = 0
    
    /// only for test
    private var enableLogPitchTime = false
    /// only for test
    private var enableAudioDump = false
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        agoraKit.disableAudio()
        mpk.stop()
        agoraKit.leaveChannel()
        mcc.destroyMusicPlayer(mpk)
        AgoraMusicContentCenter.destroy()
        AgoraRtcEngineKit.destroy()
    }
    
    func initEngine() {
        Log.debug(text: "initEngine", tag: logTag)
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
    
    func joinChannel() { /** 目的：发布mic流、接收音频流 **/
        Log.debug(text: "joinChannel", tag: logTag)
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
    
    var streamId: Int = 0
    func createDataStream() {
        let config = AgoraDataStreamConfig()
        config.syncWithAudio = false
        config.ordered = false
        let ret = agoraKit.createDataStream(&streamId, config: config)
        print("createDataStream ret \(ret)")
    }
    
    func initMCC(pid: String,
                 pKey: String,
                 token: String,
                 userId: String) {
        Log.debug(text: "initMCC", tag: logTag)
        let config = AgoraMusicContentCenterConfig()
        config.rtcEngine = agoraKit
        config.eventDelegate = self
        config.scoreEventDelegate = self
        mcc = AgoraMusicContentCenter.sharedContentCenter(config: config)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID.init().uuidString
        let dict = ["appId" : pid,
                    "appKey": pKey,
                    "token": token,
                    "userId": userId,
                    "deviceId": deviceId,
                    "urlTokenExpireTime": 15*60,
                    "chargeMode": 2] as [String : Any]
        let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [])
        let jsonStr = String(data: jsonData!, encoding: .utf8)!
        mcc.addVendor(vendorId: .vendor2, jsonVendorConfig: jsonStr)
        
        mpk = mcc.createMusicPlayer(delegate: self)
    }
    
    func preload(songCode: String) {
        Log.info(text: "preload songCode:\(songCode)", tag: logTag)
        
        let internalSongCode = mcc.getInternalSongCode(vendorId: .vendor2, songCode: songCode, jsonOption: nil)
        Log.info(text: "internalSongCode:\(internalSongCode)", tag: logTag)
        
        let _ = mcc.preload(internalSongCode: internalSongCode)
        self.songId = internalSongCode
    }
    
    func getLrc(songCode: Int, lyricType: AgoraMusicContentCenter.LyricFileType) {
        let requestId = mcc.getLyric(internalSongCode: songCode, lyricType: lyricType.rawValue)
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
    
    func startScore() {
        let ret = mcc.startScore(internalSongCode: songId)
        if ret != 0 {
            Log.errorText(text: "startScore error \(ret)", tag: logTag)
            return
        }
        Log.info(text: "startScore success", tag: logTag)
    }
    
    func pauseScore() {
        mcc.pauseScore()
    }
    
    func stopScore() {
        let ret = mcc.stopScore()
        if ret != 0 {
            Log.errorText(text: "stopScore error \(ret)", tag: logTag)
            return
        }
        Log.info(text: "stopScore success", tag: logTag)
    }
    
    func resumeScore() {
        let ret = mcc.resumeScore()
        if ret != 0 {
            Log.errorText(text: "resumeScore error \(ret)", tag: logTag)
            return
        }
        Log.info(text: "resumeScore success", tag: logTag)
    }
    
    func playMusic() {
        let ret = mpk.play()
        if ret != 0 {
            Log.errorText(text: "play error \(ret)", tag: logTag)
            return
        }
        isPause = false
        Log.info(text: "play success", tag: logTag)
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
    
    func getCumulativeScoreData() -> AgoraCumulativeScoreData {
        return mcc.getCumulativeScoreData()
    }
    
    func setScoreLevel(level: AgoraScoreLevel) {
        let ret = mcc.setScoreLevel(level: .normal)
        if ret != 0 {
            Log.errorText(text: "setScoreLevel error \(ret)", tag: logTag)
        }
        else {
            Log.info(text: "setScoreLevel \(level.rawValue) success", tag: logTag)
        }
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

extension MccManagerEx {
    private func logPitchTime(pitch: CFAbsoluteTime) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let gap = currentTime - lastPitchTime
        lastPitchTime = currentTime
        if gap > 50 {
            Log.errorText(text: "gap:[\(gap.keep3)] \(pitch)")
        }
    }
}

extension MccManagerEx: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinChannel channel: String,
                   withUid uid: UInt,
                   elapsed: Int) {
        Log.info(text: "didJoinChannel \(uid)", tag: logTag)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        Log.errorText(text:"didOccurError \(errorCode)", tag: logTag)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        Log.info(text: "didJoinedOfUid \(uid)", tag: logTag)
        createDataStream()
    }
}

extension MccManagerEx: AgoraMusicContentCenterEventDelegate {
    func onStartScoreResult(_ internalSongCode: Int,
                            state: AgoraMusicContentCenterState,
                            errorCode: AgoraMusicContentCenterStatusCode) {
        delegate?.onMccExScoreStart(self)
    }
    
    func onPreLoadEvent(_ requestId: String,
                        internalSongCode: Int,
                        percent: Int,
                        payload: String?,
                        state: AgoraMusicContentCenterState,
                        errorCode: AgoraMusicContentCenterStatusCode) {
        Log.debug(text: "onPreLoadEvent requestId:\(requestId) internalSongCode:\(internalSongCode) status:\(state) percent:\(percent) payload:\(payload ?? "nil") errorCode:\(errorCode)", tag: logTag)
        
        if state == .preloadOK, let jsonString = payload {
            Log.info(text: "preload ok", tag: logTag)
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    let dict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as! [String: Any]
                    if let lyricPath = dict["lyricPath"] as? String,
                       let pitchPath = dict["pitchPath"] as? String,
                       let songOffsetBegin = dict["songOffsetBegin"] as? Int,
                       let lyricOffset = dict["lyricOffset"] as? Int,
                       let songOffsetEnd = dict["songOffsetEnd"] as? Int {
                        Log.debug(text: "lyricPath:\(lyricPath) pitchPath:\(pitchPath) songOffsetBegin:\(songOffsetBegin) lyricOffset:\(lyricOffset) songOffsetEnd:\(songOffsetEnd)", tag: logTag)
                        
                        let lyricData = try Data(contentsOf: URL(fileURLWithPath: lyricPath))
                        let pitchData = try Data(contentsOf: URL(fileURLWithPath: pitchPath))
                        delegate?.onPreloadMusic(self,
                                                 songId: internalSongCode,
                                                 percent: percent,
                                                 lyricData: lyricData,
                                                 pitchData: pitchData,
                                                 lyricOffset: lyricOffset,
                                                 songOffsetBegin: songOffsetBegin,
                                                 errorMsg: nil)
                    }
                }
                catch {
                    Log.errorText(text: "payload json解析失败", tag: logTag)
                }
            }
        }
        
        if state == .preloadFailed {
            Log.errorText(text: "onPreLoadEvent percent:\(percent) status:\(state.rawValue) lyricUrl:\(payload ?? "null")", tag: logTag)
            if errorCode == .errorPermissionAndResource {
                Log.errorText(text: "歌曲下架")
            }
            delegate?.onPreloadMusic(self,
                                     songId: internalSongCode,
                                     percent: 0,
                                     lyricData: Data(),
                                     pitchData: Data(),
                                     lyricOffset: 0,
                                     songOffsetBegin: 0,
                                     errorMsg: "preload error")
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
                       internalSongCode: Int,
                       payload: String?,
                       errorCode: AgoraMusicContentCenterStatusCode) {
        Log.info(text: "onLyricResult requestId:\(requestId) internalSongCode:\(internalSongCode) payload:\(payload ?? "null") errorCode:\(errorCode)", tag: logTag)
        if errorCode == .OK, let jsonString = payload {
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    let dict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as! [String: Any]
                    if let lyricUrl = dict["lyricUrl"] as? String {
                        Log.debug(text: "lyricUrl:\(lyricUrl)", tag: logTag)
                        delegate?.onLyricResult(url: lyricUrl)
                    }
                }
                catch {
                    Log.errorText(text: "payload json解析失败", tag: logTag)
                }
            }
        }
    }
}

extension MccManagerEx: AgoraMusicContentCenterScoreEventDelegate {
    func onPitch(_ songCode: Int, rawScoreData: AgoraRawScoreData) {
        //        Log.debug(text: "onPitch:\(rawScoreData.speakerPitch)", tag: logTag)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.onPitch(self, rawScoreData: rawScoreData)
        }
    }
    
    func onLineScore(_ songCode: Int, lineScoreData: AgoraLineScoreData) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.onLineScore(songCode, lineScoreData: lineScoreData)
        }
    }
}

extension MccManagerEx: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            Log.info(text: "openCompleted", tag: logTag)
            delegate?.onOpenMusic(self)
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo position: Int) {}
}

extension MccManagerEx {
    func invokeOnPreloadMusic(_ manager: MccManagerEx, songId: Int, percent: Int, lyricData: Data, pitchData: Data, lyricOffset: Int, songOffsetBegin: Int, errorMsg: String?) {
        if Thread.isMainThread {
            self.delegate?.onPreloadMusic(manager,
                                          songId: songId,
                                          percent: percent,
                                          lyricData: lyricData,
                                          pitchData: pitchData,
                                          lyricOffset: lyricOffset,
                                          songOffsetBegin: songOffsetBegin,
                                          errorMsg: errorMsg)
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.onPreloadMusic(manager,
                                          songId: songId,
                                          percent: percent,
                                          lyricData: lyricData,
                                          pitchData: pitchData,
                                          lyricOffset: lyricOffset,
                                          songOffsetBegin: songOffsetBegin,
                                          errorMsg: errorMsg)
        }
    }
}
