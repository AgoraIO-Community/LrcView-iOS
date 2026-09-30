import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class TMEScoringPreparation<Model> {
    enum Status: Equatable {
        case requestingSongInfo, downloadingLyrics, lyricsDownloaded
        case downloadingPitch, pitchDownloaded, parsing
    }

    enum PreparationError: Error, Equatable {
        case requestFailed, invalidSongInfo, invalidURL, downloadFailed, invalidFiles
    }

    var onStatus: ((Status) -> Void)?
    var onCompletion: ((Result<Model, PreparationError>) -> Void)?

    private let session: URLSession
    private let parseModel: (String, String) -> Model?
    private var parser = TMEParser()
    private var requestId: String?
    private var songId: String?
    private var generation = 0
    private var directory: URL?
    private var lyricTask: URLSessionDataTask?
    private var pitchTask: URLSessionDataTask?
    private var lyricPath: String?
    private var pitchPath: String?
    private var awaitingResponse = false

    init(session: URLSession = .shared,
         parseModel: @escaping (String, String) -> Model?) {
        self.session = session
        self.parseModel = parseModel
        parser.delegate = self
    }

    func prepare(songId: String, sendRequest: (String) -> String?) {
        precondition(Thread.isMainThread)
        cancel()
        self.songId = songId
        let request: [String: Any] = [
            "vendorId": 2,
            "actionType": "song-info",
            "actionParameter": ["songIdListStr": songId]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: request),
              let option = String(data: data, encoding: .utf8) else {
            finish(.failure(.requestFailed))
            return
        }
        let current = generation
        onStatus?(.requestingSongInfo)
        guard generation == current else { return }
        guard let id = sendRequest(option), !id.isEmpty else {
            guard generation == current else { return }
            finish(.failure(.requestFailed))
            return
        }
        guard generation == current else { return }
        requestId = id
        awaitingResponse = true
    }

    @discardableResult
    func handleResponse(requestId: String, jsonOption: String,
                        httpCode: Int, response: String) -> Bool {
        precondition(Thread.isMainThread)
        guard requestId == self.requestId, awaitingResponse else { return false }
        awaitingResponse = false
        parser.parse(requestId: requestId, jsonOption: jsonOption,
                     httpCode: httpCode, responseBody: response)
        return true
    }

    func cancel() {
        precondition(Thread.isMainThread)
        parser.delegate = nil
        parser = TMEParser()
        parser.delegate = self
        generation += 1
        lyricTask?.cancel()
        pitchTask?.cancel()
        lyricTask = nil
        pitchTask = nil
        if let directory = directory { try? FileManager.default.removeItem(at: directory) }
        directory = nil
        lyricPath = nil
        pitchPath = nil
        songId = nil
        requestId = nil
        awaitingResponse = false
    }

    private func download(_ url: URL, name: String, generation: Int, lyric: Bool) {
        onStatus?(lyric ? .downloadingLyrics : .downloadingPitch)
        guard self.generation == generation else { return }
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self, self.generation == generation,
                      let directory = self.directory else { return }
                guard error == nil, let data = data, !data.isEmpty,
                      let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    self.finish(.failure(.downloadFailed))
                    return
                }
                let path = directory.appendingPathComponent(name).path
                do {
                    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
                } catch {
                    self.finish(.failure(.downloadFailed))
                    return
                }
                if lyric {
                    self.lyricPath = path
                    self.onStatus?(.lyricsDownloaded)
                } else {
                    self.pitchPath = path
                    self.onStatus?(.pitchDownloaded)
                }
                guard self.generation == generation else { return }
                guard let pitchPath = self.pitchPath, let lyricPath = self.lyricPath else { return }
                self.onStatus?(.parsing)
                guard self.generation == generation else { return }
                guard let model = self.parseModel(pitchPath, lyricPath) else {
                    self.finish(.failure(.invalidFiles))
                    return
                }
                self.finish(.success(model))
            }
        }
        if lyric { lyricTask = task } else { pitchTask = task }
        task.resume()
    }

    private func finish(_ result: Result<Model, PreparationError>) {
        let completion = onCompletion
        if case .success = result {
            lyricTask = nil
            pitchTask = nil
            requestId = nil
            songId = nil
            awaitingResponse = false
        } else {
            cancel()
        }
        completion?(result)
    }
}

extension TMEScoringPreparation: TMEParserDelegate {
    func onSongInfo(_ requestId: String, result: TMESongInfoResult) {
        guard requestId == self.requestId, let songId = songId else { return }
        guard let detail = result.songList.first(where: { $0.songId == songId }),
              let pitch = detail.pitchUrl, !pitch.isEmpty,
              let lyric = detail.lrcList?.first(where: {
                  $0.type == "lrc" && !$0.url.isEmpty
              })?.url else {
            finish(.failure(.invalidSongInfo))
            return
        }
        guard let pitchURL = URL(string: pitch), let lyricURL = URL(string: lyric),
              [pitchURL, lyricURL].allSatisfy({ ["https", "http"].contains($0.scheme?.lowercased() ?? "") && $0.host != nil }) else {
            finish(.failure(.invalidURL))
            return
        }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("tme-scoring-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        } catch {
            finish(.failure(.downloadFailed))
            return
        }
        self.directory = directory
        let current = generation
        download(lyricURL, name: "song_lyric.lrc", generation: current, lyric: true)
        guard generation == current else { return }
        download(pitchURL, name: "song_pitch.json", generation: current, lyric: false)
    }

    func onParseError(_ requestId: String, jsonOption: String,
                      responseBody: String, error: TMEParseError) {
        guard requestId == self.requestId else { return }
        finish(.failure(.invalidSongInfo))
    }
}
