import AgoraLyricsScore
import AgoraRtcKit
import Foundation

protocol AgoraSDKLifecycleManaging {
    func replaceSharedInstances(then start: @escaping () -> Void)
    func destroySharedInstances()
}

final class AgoraSDKLifecycleManager: AgoraSDKLifecycleManaging {
    private static let queue = DispatchQueue(label: "io.agora.KLyricsDemo.sdk-lifecycle")

    func replaceSharedInstances(then start: @escaping () -> Void) {
        Self.queue.async {
            Self.destroy()
            DispatchQueue.main.sync(execute: start)
        }
    }

    func destroySharedInstances() {
        Self.queue.async {
            Self.destroy()
        }
    }

    private static func destroy() {
        AgoraMusicContentCenter.destroy()
        AgoraRtcEngineKit.destroy()
    }
}

final class AgoraKaraokeClient: NSObject, KaraokeClientProtocol {
    weak var delegate: KaraokeClientDelegate?

    private var engine: AgoraRtcEngineKit?
    private var contentCenter: AgoraMusicContentCenter?
    private var player: AgoraMusicPlayerProtocol?
    private let lifecycle: AgoraSDKLifecycleManaging
    private let lyricsDownloader = LyricsFileDownloader()
    private var preparationId: UUID?
    private var preloadRequestId: String?
    private var lyricResultRequestId: String?
    private var lyricsDownloadRequestId: Int?
    private var progressTimer: Timer?
    private var currentSong: Song?
    private var audioTrackIndex: Int32 = 1
    private var isPlaying = false

    override convenience init() {
        self.init(lifecycle: AgoraSDKLifecycleManager())
    }

    init(lifecycle: AgoraSDKLifecycleManaging) {
        self.lifecycle = lifecycle
        super.init()
        lyricsDownloader.delegate = self
    }

    static func mapPreloadError(_ code: AgoraMusicContentCenterStatusCode) -> KaraokeError {
        switch code {
        case .errorPermissionAndResource:
            return .songUnavailable
        case .errorGateway, .errorHttpInternalError:
            return .network
        default:
            return .playback(code: Int(code.rawValue))
        }
    }

    static func mapDownloadFailure() -> KaraokeError {
        .lyrics
    }

    static func mapPlayerError(rawValue: Int) -> KaraokeError {
        .playback(code: rawValue)
    }

    static func matchesCallback(
        requestId: String,
        songCode: Int,
        expectedRequestId: String?,
        currentSong: Song?
    ) -> Bool {
        requestId == expectedRequestId && songCode == currentSong?.id
    }

    func prepare(song: Song, credentials: AgoraCredentials, access: KaraokeAccess) {
        cleanup(destroySharedInstances: false)
        currentSong = song
        audioTrackIndex = 1
        lyricsDownloader.delegate = self

        let preparationId = UUID()
        self.preparationId = preparationId
        lifecycle.replaceSharedInstances { [weak self] in
            guard let self, self.preparationId == preparationId else { return }
            self.prepareSDK(song: song, credentials: credentials, access: access)
        }
    }

    private func prepareSDK(song: Song, credentials: AgoraCredentials, access: KaraokeAccess) {
        let config = AgoraRtcEngineConfig()
        config.appId = credentials.appId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        let engine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        self.engine = engine

        engine.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        engine.enableAudio()
        engine.setClientRole(.broadcaster)

        let options = AgoraRtcChannelMediaOptions()
        options.clientRoleType = .broadcaster
        let joinCode = engine.joinChannel(
            byToken: access.rtcToken,
            channelId: access.channelName,
            uid: access.uid,
            mediaOptions: options
        )
        guard joinCode == 0 else {
            fail(.playback(code: Int(joinCode)))
            return
        }

        let mccConfig = AgoraMusicContentCenterConfig()
        mccConfig.rtcEngine = engine
        mccConfig.mccUid = Int(access.uid)
        mccConfig.token = access.mccToken
        mccConfig.appId = credentials.appId
        guard let contentCenter = AgoraMusicContentCenter.sharedContentCenter(config: mccConfig) else {
            fail(.network)
            return
        }
        self.contentCenter = contentCenter
        contentCenter.enableMainQueueDispatch(true)
        contentCenter.register(self)

        guard let player = contentCenter.createMusicPlayer(delegate: self) else {
            fail(.playback(code: -1))
            return
        }
        self.player = player
        let requestId = contentCenter.preload(songCode: song.id)
        guard !requestId.isEmpty else {
            fail(.network)
            return
        }
        preloadRequestId = requestId
    }

    func pause() {
        guard let player else { return }
        let code = player.pause()
        guard code == 0 else {
            fail(.playback(code: Int(code)))
            return
        }
        isPlaying = false
    }

    func resume() {
        guard let player else { return }
        let code = player.resume()
        guard code == 0 else {
            fail(.playback(code: Int(code)))
            return
        }
        isPlaying = true
    }

    func seek(milliseconds: Int) {
        guard let player else { return }
        let code = player.seek(toPosition: milliseconds)
        if code != 0 {
            fail(.playback(code: Int(code)))
        }
    }

    func toggleAudioTrack() {
        guard let player else { return }
        let nextIndex: Int32 = audioTrackIndex == 1 ? 0 : 1
        let code = player.selectAudioTrack(nextIndex)
        guard code == 0 else {
            fail(.playback(code: Int(code)))
            return
        }
        audioTrackIndex = nextIndex
    }

    func cleanup() {
        cleanup(destroySharedInstances: true)
    }

    private func cleanup(destroySharedInstances: Bool) {
        progressTimer?.invalidate()
        progressTimer = nil
        isPlaying = false
        preparationId = nil
        preloadRequestId = nil
        lyricResultRequestId = nil

        if let requestId = lyricsDownloadRequestId {
            lyricsDownloader.cancelDownload(requestId: requestId)
            lyricsDownloadRequestId = nil
        }
        lyricsDownloader.delegate = nil

        if let player {
            player.stop()
        }
        contentCenter?.register(nil)
        engine?.leaveChannel()
        if let player {
            engine?.destroyMediaPlayer(player)
        }
        engine?.delegate = nil

        player = nil
        contentCenter = nil
        engine = nil
        currentSong = nil

        if destroySharedInstances {
            lifecycle.destroySharedInstances()
        }
    }

    private func requestLyrics(for songCode: Int) {
        guard let contentCenter else { return }
        let requestId = contentCenter.getLyric(songCode: songCode, lyricType: 0)
        guard !requestId.isEmpty else {
            fail(.lyrics)
            return
        }
        lyricResultRequestId = requestId
    }

    private func downloadLyrics(from url: String) {
        let requestId = lyricsDownloader.download(urlString: url)
        guard requestId >= 0 else {
            fail(Self.mapDownloadFailure())
            return
        }
        lyricsDownloadRequestId = requestId
    }

    private func openCurrentSong() {
        guard let song = currentSong, let player else { return }
        let code = player.openMedia(songCode: song.id, startPos: 0)
        if code != 0 {
            fail(.playback(code: Int(code)))
        }
    }

    private func startPlayback() {
        guard let player else { return }
        let code = player.play()
        guard code == 0 else {
            fail(.playback(code: Int(code)))
            return
        }
        isPlaying = true
        startProgressTimer()
        notify { delegate, client in
            delegate.clientDidStartPlayback(client)
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            let position = player.getPosition()
            guard position >= 0 else { return }
            self.delegate?.client(self, didUpdateProgress: position)
        }
    }

    private func finishPlayback() {
        progressTimer?.invalidate()
        progressTimer = nil
        isPlaying = false
        notify { delegate, client in
            delegate.clientDidFinishPlayback(client)
        }
    }

    private func fail(_ error: KaraokeError) {
        isPlaying = false
        progressTimer?.invalidate()
        progressTimer = nil
        notify { delegate, client in
            delegate.client(client, didFail: error)
        }
    }

    private func notify(_ callback: @escaping (KaraokeClientDelegate, AgoraKaraokeClient) -> Void) {
        let work = { [weak self] in
            guard let self, let delegate = self.delegate else { return }
            callback(delegate, self)
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}

extension AgoraKaraokeClient: AgoraMusicContentCenterEventDelegate {
    func onPreLoadEvent(
        _ requestId: String,
        songCode: Int,
        percent: Int,
        lyricUrl: String?,
        status: AgoraMusicContentCenterPreloadStatus,
        errorCode: AgoraMusicContentCenterStatusCode
    ) {
        guard Self.matchesCallback(
            requestId: requestId,
            songCode: songCode,
            expectedRequestId: preloadRequestId,
            currentSong: currentSong
        ) else { return }

        if status == .OK {
            preloadRequestId = nil
            requestLyrics(for: songCode)
        } else if status == .error {
            preloadRequestId = nil
            fail(Self.mapPreloadError(errorCode))
        }
    }

    func onLyricResult(
        _ requestId: String,
        songCode: Int,
        lyricUrl: String?,
        errorCode: AgoraMusicContentCenterStatusCode
    ) {
        guard Self.matchesCallback(
            requestId: requestId,
            songCode: songCode,
            expectedRequestId: lyricResultRequestId,
            currentSong: currentSong
        ) else { return }
        lyricResultRequestId = nil

        guard errorCode == .OK, let lyricUrl, !lyricUrl.isEmpty else {
            fail(errorCode == .OK ? .lyrics : Self.mapPreloadError(errorCode))
            return
        }
        downloadLyrics(from: lyricUrl)
    }

    func onMusicChartsResult(
        _ requestId: String,
        result: [AgoraMusicChartInfo],
        errorCode: AgoraMusicContentCenterStatusCode
    ) {}

    func onMusicCollectionResult(
        _ requestId: String,
        result: AgoraMusicCollection,
        errorCode: AgoraMusicContentCenterStatusCode
    ) {}

    func onSongSimpleInfoResult(
        _ requestId: String,
        songCode: Int,
        simpleInfo: String?,
        errorCode: AgoraMusicContentCenterStatusCode
    ) {}
}

extension AgoraKaraokeClient: LyricsFileDownloaderDelegate {
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {}

    func onLyricsFileDownloadCompleted(requestId: Int, fileData: Data?, error: DownloadError?) {
        guard requestId == lyricsDownloadRequestId else { return }
        lyricsDownloadRequestId = nil
        guard error == nil,
              let fileData,
              let lyrics = KaraokeView.parseLyricData(lyricFileData: fileData) else {
            fail(Self.mapDownloadFailure())
            return
        }

        notify { delegate, client in
            delegate.client(client, didLoad: lyrics)
            client.openCurrentSong()
        }
    }
}

extension AgoraKaraokeClient: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(
        _ playerKit: AgoraRtcMediaPlayerProtocol,
        didChangedTo state: AgoraMediaPlayerState,
        error: AgoraMediaPlayerError
    ) {
        guard playerKit.getMediaPlayerId() == player?.getMediaPlayerId() else { return }
        switch state {
        case .openCompleted:
            notify { _, client in client.startPlayback() }
        case .playBackCompleted, .playBackAllLoopsCompleted:
            finishPlayback()
        case .failed:
            fail(Self.mapPlayerError(rawValue: Int(error.rawValue)))
        default:
            break
        }
    }

    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo position: Int) {}
}

extension AgoraKaraokeClient: AgoraRtcEngineDelegate {
    func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo],
        totalVolume: Int
    ) {
        guard engine === self.engine, isPlaying, let pitch = speakers.last?.voicePitch else { return }
        notify { delegate, client in
            delegate.client(client, didUpdatePitch: pitch)
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        guard engine === self.engine else { return }
        fail(.playback(code: Int(errorCode.rawValue)))
    }
}
