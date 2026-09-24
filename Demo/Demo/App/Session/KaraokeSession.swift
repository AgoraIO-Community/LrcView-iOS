import AgoraLyricsScore

enum KaraokeSessionState: Equatable {
    case idle
    case preparing(Song)
    case ready(Song)
    case playing(Song)
    case paused(Song)
    case finished(Song)
    case failed(Song?, KaraokeError)
}

protocol KaraokeClientDelegate: AnyObject {
    func client(_ client: KaraokeClientProtocol, didLoad lyrics: LyricModel)
    func clientDidStartPlayback(_ client: KaraokeClientProtocol)
    func client(_ client: KaraokeClientProtocol, didUpdateProgress milliseconds: Int)
    func client(_ client: KaraokeClientProtocol, didUpdatePitch pitch: Double)
    func client(_ client: KaraokeClientProtocol, didFail error: KaraokeError)
    func clientDidFinishPlayback(_ client: KaraokeClientProtocol)
}

protocol KaraokeClientProtocol: AnyObject {
    var delegate: KaraokeClientDelegate? { get set }
    func prepare(song: Song, credentials: AgoraCredentials, access: KaraokeAccess)
    func pause()
    func resume()
    func seek(milliseconds: Int)
    func toggleAudioTrack()
    func cleanup()
}

protocol KaraokeSessionDelegate: AnyObject {
    func session(_ session: KaraokeSessionControlling, didChange state: KaraokeSessionState)
    func session(_ session: KaraokeSessionControlling, didLoad lyrics: LyricModel)
    func session(_ session: KaraokeSessionControlling, didUpdateProgress milliseconds: Int)
    func session(_ session: KaraokeSessionControlling, didUpdatePitch pitch: Double)
}

protocol KaraokeSessionControlling: AnyObject {
    var delegate: KaraokeSessionDelegate? { get set }
    var state: KaraokeSessionState { get }
    func start(song: Song, credentials: AgoraCredentials)
    func pause()
    func resume()
    func seek(milliseconds: Int)
    func toggleAudioTrack()
    func stop()
}

final class KaraokeSession: KaraokeSessionControlling {
    weak var delegate: KaraokeSessionDelegate?
    private(set) var state: KaraokeSessionState = .idle

    private let client: KaraokeClientProtocol
    private let tokenProvider: TokenProviding
    private var hasActiveClient = false
    private var currentSong: Song?

    init(client: KaraokeClientProtocol, tokenProvider: TokenProviding) {
        self.client = client
        self.tokenProvider = tokenProvider
        client.delegate = self
    }

    func start(song: Song, credentials: AgoraCredentials) {
        if hasActiveClient {
            cleanupClient()
        }
        currentSong = song
        changeState(to: .preparing(song))

        do {
            let access = try tokenProvider.makeAccess(credentials: credentials)
            hasActiveClient = true
            client.prepare(song: song, credentials: credentials, access: access)
        } catch {
            changeState(to: .failed(song, .credentials))
        }
    }

    func pause() {
        guard case let .playing(song) = state else { return }
        client.pause()
        guard state == .playing(song) else { return }
        changeState(to: .paused(song))
    }

    func resume() {
        guard case let .paused(song) = state else { return }
        client.resume()
        guard state == .paused(song) else { return }
        changeState(to: .playing(song))
    }

    func seek(milliseconds: Int) {
        guard hasActiveClient else { return }
        client.seek(milliseconds: milliseconds)
    }

    func toggleAudioTrack() {
        guard hasActiveClient else { return }
        client.toggleAudioTrack()
    }

    func stop() {
        cleanupClient()
        currentSong = nil
        if state != .idle {
            changeState(to: .idle)
        }
    }

    private func cleanupClient() {
        guard hasActiveClient else { return }
        hasActiveClient = false
        client.cleanup()
    }

    private func changeState(to newState: KaraokeSessionState) {
        state = newState
        delegate?.session(self, didChange: newState)
    }
}

extension KaraokeSession: KaraokeClientDelegate {
    func client(_ client: KaraokeClientProtocol, didLoad lyrics: LyricModel) {
        guard let song = currentSong else { return }
        changeState(to: .ready(song))
        delegate?.session(self, didLoad: lyrics)
    }

    func clientDidStartPlayback(_ client: KaraokeClientProtocol) {
        guard let song = currentSong else { return }
        changeState(to: .playing(song))
    }

    func client(_ client: KaraokeClientProtocol, didUpdateProgress milliseconds: Int) {
        delegate?.session(self, didUpdateProgress: milliseconds)
    }

    func client(_ client: KaraokeClientProtocol, didUpdatePitch pitch: Double) {
        delegate?.session(self, didUpdatePitch: pitch)
    }

    func client(_ client: KaraokeClientProtocol, didFail error: KaraokeError) {
        let song = currentSong
        cleanupClient()
        changeState(to: .failed(song, error))
    }

    func clientDidFinishPlayback(_ client: KaraokeClientProtocol) {
        guard let song = currentSong else { return }
        cleanupClient()
        changeState(to: .finished(song))
    }
}
