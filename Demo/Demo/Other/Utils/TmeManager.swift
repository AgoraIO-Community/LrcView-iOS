import Foundation
import AVFoundation
import AgoraRtcKit
import RTMTokenBuilder
import AgoraLyricsScore

protocol TmeManagerDelegate: AnyObject {
    func tmeManager(_ manager: TmeManager, didLoad songs: [TmeSong])
    func tmeManager(_ manager: TmeManager, didUpdate status: String)
    func tmeManager(_ manager: TmeManager, didFail message: String)
    func tmeManager(_ manager: TmeManager, didChangePlayback isPlaying: Bool)
    func tmeManager(_ manager: TmeManager, didUpdateResource status: TMEScoringPreparation<LyricModel>.Status)
    func tmeManager(_ manager: TmeManager, didPrepare model: LyricModel?)
    func tmeManager(_ manager: TmeManager, didFailPreparation error: TMEScoringPreparation<LyricModel>.PreparationError)
    func tmeManager(_ manager: TmeManager, didReceivePitch pitch: Double)
}

extension TmeManagerDelegate {
    func tmeManager(_ manager: TmeManager, didUpdateResource status: TMEScoringPreparation<LyricModel>.Status) {}
    func tmeManager(_ manager: TmeManager, didPrepare model: LyricModel?) {}
    func tmeManager(_ manager: TmeManager, didFailPreparation error: TMEScoringPreparation<LyricModel>.PreparationError) {}
    func tmeManager(_ manager: TmeManager, didReceivePitch pitch: Double) {}
}

final class TmeManager: NSObject {
    weak var delegate: TmeManagerDelegate?

    private var rtc: AgoraRtcEngineKit?
    private var mcc: AgoraMusicContentCenter?
    private var player: AgoraMusicPlayerProtocol?
    private let songsRequest = TMEResponseTracker()
    private let responseParser = TMEParser()
    private lazy var microphonePermission = TMEMicrophonePermissionGate(
        status: {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted: return .granted
            case .denied: return .denied
            case .undetermined: return .undetermined
            @unknown default: return .denied
            }
        },
        request: { completion in
            AVAudioSession.sharedInstance().requestRecordPermission(completion)
        }
    )
    private var preloadRequestId: String?
    private var selectedSongCode: Int?
    private(set) var currentTMESongId: String?
    private var isPlaying = false
    private var scoringActive = false
    private let sessionLock = NSLock()
    private var playbackSession = 0
    private var playbackGate: TMEPlaybackGate?
    private lazy var scoringPreparation: TMEScoringPreparation<LyricModel> = {
        let preparation = TMEScoringPreparation<LyricModel> { pitchFile, lyricFile in
            KaraokeView.parseTMEToneData(pitchFile, lyricFile)
        }
        preparation.onStatus = { [weak self] state in
            guard let self = self else { return }
            self.delegate?.tmeManager(self, didUpdateResource: state)
        }
        preparation.onCompletion = { [weak self] result in
            guard let self = self, self.selectedSongCode != nil else { return }
            switch result {
            case .success(let model):
                self.delegate?.tmeManager(self, didPrepare: model)
                self.playbackGate?.resourcesReady()
            case .failure(let error):
                self.delegate?.tmeManager(self, didPrepare: nil)
                self.delegate?.tmeManager(self, didFailPreparation: error)
                self.playbackGate?.resourcesFailed()
            }
        }
        return preparation
    }()
    private(set) var canTogglePlayback = false

    override init() {
        super.init()
        responseParser.delegate = self
    }

    func start() {
        guard !Config.rtcAppId.isEmpty, !Config.rtcCertificate.isEmpty,
              !Config.mccAppId.isEmpty, !Config.mccCertificate.isEmpty else {
            fail("请在 localConfig.swift 中配置 RTC 和 MCC 的 App ID、证书")
            return
        }
        if mcc != nil {
            requestSongs()
            return
        }
        microphonePermission.authorize { [weak self] allowed in
            guard let self = self else { return }
            guard allowed else {
                self.fail("请在系统设置中允许麦克风权限后重试")
                return
            }
            self.startRtc()
        }
    }

    private func startRtc() {
        if rtc != nil { stop() }

        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        let engine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        rtc = engine
        let token = TokenBuilder.rtcToken2(Config.rtcAppId,
                                            appCertificate: Config.rtcCertificate,
                                            uid: Int32(Config.hostUid),
                                            channelName: Config.channelId)
        guard !token.isEmpty else {
            fail("RTC token 生成失败")
            return
        }
        let options = AgoraRtcChannelMediaOptions()
        options.clientRoleType = .broadcaster
        engine.enableAudio()
        engine.enableAudioVolumeIndication(200, smooth: 3, reportVad: true)
        engine.setClientRole(.broadcaster)
        status("正在加入 RTC")
        let result = engine.joinChannel(byToken: token,
                                        channelId: Config.channelId,
                                        uid: Config.hostUid,
                                        mediaOptions: options)
        if result != 0 { fail("RTC 入会失败：\(result)") }
    }

    private func initializeMcc() {
        let token = TokenBuilder.buildRtmToken2(Config.mccAppId,
                                                appCertificate: Config.mccCertificate,
                                                userUuid: "\(Config.mccUid)")
        guard !token.isEmpty else {
            fail("MCC token 生成失败")
            return
        }
        let config = AgoraMusicContentCenterConfig()
        config.rtcEngine = rtc
        config.appId = Config.mccAppId
        config.token = token
        config.mccUid = Config.mccUid
        if let domain = Config.mccDomain { config.mccDomain = domain }
        guard let center = AgoraMusicContentCenter.sharedContentCenter(config: config) else {
            fail("MCC 初始化失败")
            return
        }
        mcc = center
        center.register(self)
        requestSongs()
    }

    func requestSongs() {
        guard let center = mcc else {
            start()
            return
        }
        songsRequest.clear()
        let request: [String: Any] = [
            "vendorId": 2,
            "actionType": "songs",
            "actionParameter": ["queryInfo": "", "limit": 20]
        ]
        guard let json = jsonString(request),
              let requestId = center.sendExtRequest(jsonOption: json), !requestId.isEmpty else {
            fail("歌曲列表请求提交失败")
            return
        }
        songsRequest.set(requestId)
        status("正在获取歌曲")
    }

    func select(_ song: TmeSong) {
        guard let center = mcc else { return }
        stopSong()
        guard let musicPlayer = center.createMusicPlayer(delegate: self) else {
            fail("无法创建音乐播放器")
            return
        }
        player = musicPlayer
        currentTMESongId = song.id
        let gate = TMEPlaybackGate()
        gate.onStart = { [weak self] mode in
            guard let self = self, self.selectedSongCode != nil else { return }
            self.scoringActive = mode == .playWithScoring
            guard musicPlayer.play() == 0 else {
                self.scoringActive = false
                self.fail("播放歌曲失败")
                return
            }
            self.isPlaying = true
            self.canTogglePlayback = true
            self.playbackChanged()
            self.status("正在播放")
        }
        playbackGate = gate

        let option: [String: Any] = [
            "vendorId": 2,
            "actionParameter": ["songCode": song.id, "fileType": "mkv"]
        ]
        guard let json = jsonString(option) else {
            fail("歌曲参数构造失败")
            return
        }
        let code = center.getInternalSongCode(songCode: 0, jsonOption: json)
        guard code >= 0 else {
            fail("歌曲编号转换失败：\(code)")
            return
        }
        selectedSongCode = code
        let requestId = center.preload(songCode: code)
        guard !requestId.isEmpty else {
            fail("预加载请求提交失败")
            return
        }
        preloadRequestId = requestId
        status("正在预加载 \(song.name)")
    }

    func togglePlayback() {
        guard let musicPlayer = player, selectedSongCode != nil, canTogglePlayback else { return }
        let result = isPlaying ? musicPlayer.pause() : musicPlayer.resume()
        if result == 0 {
            isPlaying.toggle()
            playbackChanged()
            status(isPlaying ? "正在播放" : "已暂停")
        } else {
            fail("播放操作失败：\(result)")
        }
    }

    func playerPosition() -> UInt? {
        let position = player?.getPosition() ?? -1
        return position >= 0 ? UInt(position) : nil
    }

    func stopSong() {
        sessionLock.lock()
        playbackSession += 1
        sessionLock.unlock()
        scoringPreparation.cancel()
        playbackGate?.stop()
        playbackGate = nil
        player?.stop()
        if let player = player { mcc?.destroyMusicPlayer(player) }
        player = nil
        preloadRequestId = nil
        selectedSongCode = nil
        currentTMESongId = nil
        scoringActive = false
        isPlaying = false
        canTogglePlayback = false
        playbackChanged()
    }

    func stop() {
        microphonePermission.cancel()
        guard rtc != nil || mcc != nil else { return }
        songsRequest.clear()
        stopSong()
        mcc?.register(nil)
        mcc = nil
        AgoraMusicContentCenter.destroy()
        rtc?.leaveChannel()
        rtc?.disableAudio()
        rtc = nil
        AgoraRtcEngineKit.destroy()
    }

    deinit { stop() }

    private func jsonString(_ object: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func status(_ message: String) {
        notify { manager, recipient in recipient.tmeManager(manager, didUpdate: message) }
    }

    private func fail(_ message: String) {
        notify { manager, recipient in recipient.tmeManager(manager, didFail: message) }
    }

    private func playbackChanged() {
        let value = isPlaying
        notify { manager, recipient in recipient.tmeManager(manager, didChangePlayback: value) }
    }

    private func currentSession() -> Int {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        return playbackSession
    }

    private func notify(_ action: @escaping (TmeManager, TmeManagerDelegate) -> Void) {
        if !Thread.isMainThread {
            let session = currentSession()
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.currentSession() == session else { return }
                self.notify(action)
            }
            return
        }
        let session = currentSession()
        weak var recipient = delegate
        let deliver = { [weak self, weak recipient] in
            guard let self = self, let recipient = recipient,
                  self.currentSession() == session, self.delegate === recipient else { return }
            action(self, recipient)
        }
        deliver()
    }
}

extension TmeManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo],
                   totalVolume: Int) {
        guard let pitch = speakers.first(where: { $0.uid == 0 })?.voicePitch else { return }
        let session = currentSession()
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.currentSession() == session,
                  self.scoringActive, self.isPlaying else { return }
            self.delegate?.tmeManager(self, didReceivePitch: pitch)
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinChannel channel: String,
                   withUid uid: UInt,
                   elapsed: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.mcc == nil else { return }
            self.status("正在连接 MCC")
            self.initializeMcc()
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        fail("RTC 错误：\(errorCode.rawValue)")
    }
}

extension TmeManager: AgoraMusicContentCenterEventDelegate {
    func onExtResponse(_ requestId: String, jsonOption: String, httpCode: Int, response: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.scoringPreparation.handleResponse(requestId: requestId,
                                                       jsonOption: jsonOption,
                                                       httpCode: httpCode,
                                                       response: response) {
                self.responseParser.parse(requestId: requestId, jsonOption: jsonOption,
                                          httpCode: httpCode, responseBody: response)
            }
        }
    }

    func onPreLoadEvent(_ requestId: String, songCode: Int, percent: Int,
                        lyricUrl: String?, state: AgoraMusicContentCenterPreloadState,
                        reason: AgoraMusicContentCenterStateReason) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, requestId == self.preloadRequestId,
                  songCode == self.selectedSongCode else { return }
            if state == .error {
                self.preloadRequestId = nil
                self.fail("歌曲预加载失败：\(reason.rawValue)")
            } else if state == .OK {
                self.preloadRequestId = nil
                if let id = self.currentTMESongId, let center = self.mcc {
                    self.scoringPreparation.prepare(songId: id) {
                        center.sendExtRequest(jsonOption: $0)
                    }
                } else {
                    self.playbackGate?.resourcesFailed()
                }
                guard self.player?.openMedia(songCode: songCode, startPos: 0) == 0 else {
                    self.scoringPreparation.cancel()
                    self.fail("打开歌曲失败")
                    return
                }
                self.status("正在打开歌曲")
            } else {
                self.status("预加载 \(percent)%")
            }
        }
    }

    func onMusicChartsResult(_ requestId: String, result: [AgoraMusicChartInfo],
                             reason: AgoraMusicContentCenterStateReason) {}
    func onMusicCollectionResult(_ requestId: String, result: AgoraMusicCollection,
                                 reason: AgoraMusicContentCenterStateReason) {}
    func onSongSimpleInfoResult(_ requestId: String, songCode: Int, simpleInfo: String?,
                                reason: AgoraMusicContentCenterStateReason) {}
    func onLyricResult(_ requestId: String, songCode: Int, lyricUrl: String?,
                       reason: AgoraMusicContentCenterStateReason) {}
}

extension TmeManager: TMEParserDelegate {
    func onSongs(_ requestId: String, result: TMESongsResult) {
        songsRequest.deliverIfCurrent(requestId) { isStillCurrent in
            let songs = Array(result.songList.filter { !$0.songId.isEmpty }.prefix(6)).map {
                TmeSong(id: $0.songId, name: $0.songName,
                        artist: $0.artistList?.first?.artistName ?? "")
            }
            delegate?.tmeManager(self, didLoad: songs)
            guard isStillCurrent() else { return }
            delegate?.tmeManager(self, didUpdate: songs.isEmpty ? "暂无歌曲" : "请选择歌曲")
        }
    }

    func onParseError(_ requestId: String, jsonOption: String,
                      responseBody: String, error: TMEParseError) {
        songsRequest.deliverIfCurrent(requestId) { _ in
            delegate?.tmeManager(self, didFail: "歌曲列表获取失败：\(error)")
        }
    }
}

extension TmeManager: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol,
                             didChangedTo state: AgoraMediaPlayerState,
                             reason error: AgoraMediaPlayerReason) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let current = self.player,
                  (playerKit as AnyObject) === (current as AnyObject),
                  self.selectedSongCode != nil else { return }
            if state == .failed {
                let operation = self.canTogglePlayback ? "播放" : "打开"
                self.stopSong()
                self.fail("\(operation)歌曲失败：\(error.rawValue)")
                return
            }
            if state == .playBackCompleted || state == .playBackAllLoopsCompleted {
                self.isPlaying = false
                self.canTogglePlayback = false
                self.scoringActive = false
                self.playbackChanged()
                self.status("播放结束")
                return
            }
            guard state == .openCompleted else { return }
            self.playbackGate?.mediaOpened()
        }
    }
}
