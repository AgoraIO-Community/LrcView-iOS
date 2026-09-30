import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private final class ResourceURLProtocol: URLProtocol {
    static var bodies = [String: Data]()
    private static let lock = NSLock()
    private static var urls = [URL]()
    static var requestedURLs: [URL] {
        get { lock.lock(); defer { lock.unlock() }; return urls }
        set { lock.lock(); defer { lock.unlock() }; urls = newValue }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.lock.lock()
        Self.urls.append(url)
        Self.lock.unlock()
        if let data = Self.bodies[url.path] {
            let response = HTTPURLResponse(url: url, statusCode: 200,
                                           httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
        }
    }

    override func stopLoading() {}
}

@main
struct TMEScoringPreparationTests {
    static func main() throws {
        try testRequestContainsOriginalSongId()
        try testSelectsMatchingSongAndLRC()
        try testSkipsEmptyLRCUrl()
        try testMissingLRCFails()
        try testDownloadAndParsingFailures()
        testCancelDuringStatusStopsOtherDownloads()
        testCancelBeforeParsingSkipsModel()
        testCancelIgnoresLateResponse()
        testOldParserCallbackCannotAffectNewSongWithReusedRequestId()
        print("TMEScoringPreparationTests passed")
    }

    private static func testRequestContainsOriginalSongId() throws {
        let preparation = TMEScoringPreparation<String>(parseModel: { _, _ in "model" })
        var submitted = ""
        preparation.prepare(songId: "tme-song-42") { json in
            submitted = json
            return "request-1"
        }

        let object = try JSONSerialization.jsonObject(with: Data(submitted.utf8))
        let request = try require(object as? [String: Any])
        precondition(request["vendorId"] as? Int == 2)
        precondition(request["actionType"] as? String == "song-info")
        let parameters = try require(request["actionParameter"] as? [String: String])
        precondition(parameters["songIdListStr"] == "tme-song-42")

        preparation.cancel()
    }

    private static func testSelectsMatchingSongAndLRC() throws {
        ResourceURLProtocol.bodies = [
            "/pitch": Data("[{\"st\":\"1000\",\"d\":\"200\",\"p\":\"54\"}]".utf8),
            "/lyric": Data("[00:01.00]唱句".utf8)
        ]
        ResourceURLProtocol.requestedURLs = []
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ResourceURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        var localPaths = [String]()
        let preparation = TMEScoringPreparation<String>(session: session) { pitchPath, lyricPath in
            localPaths = [pitchPath, lyricPath]
            precondition((try? String(contentsOfFile: pitchPath))?.contains("1000") == true)
            precondition((try? String(contentsOfFile: lyricPath)) == "[00:01.00]唱句")
            return "parsed"
        }
        var statuses = [TMEScoringPreparation<String>.Status]()
        var result: Result<String, TMEScoringPreparation<String>.PreparationError>?
        preparation.onStatus = { statuses.append($0) }
        preparation.onCompletion = { result = $0 }
        var requestOption = ""
        preparation.prepare(songId: "wanted") { json in
            requestOption = json
            return "info-request"
        }
        let response = #"{"code":0,"data":{"songList":[{"songId":"other","songName":"别首","pitchUrl":"https://example.test/wrong","lrcList":[]},{"songId":"wanted","songName":"目标","pitchUrl":"https://example.test/pitch?signature=a","lrcList":[{"type":"krc","url":"https://example.test/wrong"},{"type":"lrc","url":"https://example.test/lyric?signature=b"}]}]}}"#
        precondition(preparation.handleResponse(requestId: "info-request", jsonOption: requestOption,
                                            httpCode: 200, response: response))
        waitUntil { result != nil }
        let model = try result?.get()
        precondition(model == "parsed")
        precondition(statuses.contains(.downloadingLyrics))
        precondition(statuses.contains(.lyricsDownloaded))
        precondition(statuses.contains(.downloadingPitch))
        precondition(statuses.contains(.pitchDownloaded))
        precondition(ResourceURLProtocol.requestedURLs.map(\.path).sorted() == ["/lyric", "/pitch"])
        precondition(ResourceURLProtocol.requestedURLs.allSatisfy { $0.query?.hasPrefix("signature=") == true })
        precondition(localPaths.count == 2)
        preparation.cancel()
    }

    private static func testMissingLRCFails() throws {
        let preparation = TMEScoringPreparation<String>(parseModel: { _, _ in "model" })
        var result: Result<String, TMEScoringPreparation<String>.PreparationError>?
        preparation.onCompletion = { result = $0 }
        preparation.prepare(songId: "wanted") { _ in "request-missing" }
        let response = #"{"code":0,"data":{"songList":[{"songId":"wanted","songName":"test","pitchUrl":"https://example.test/pitch","lrcList":[{"type":"krc","url":"https://example.test/krc"}]}]}}"#
        precondition(preparation.handleResponse(requestId: "request-missing",
                                            jsonOption: infoOption, httpCode: 200, response: response))
        waitUntil { result != nil }
        guard case .failure(.invalidSongInfo) = result else { preconditionFailure("expected invalid song info") }
    }

    private static func testSkipsEmptyLRCUrl() throws {
        ResourceURLProtocol.bodies = [
            "/pitch": Data("pitch".utf8),
            "/lyric": Data("lyric".utf8)
        ]
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ResourceURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let preparation = TMEScoringPreparation<String>(session: session) { _, _ in "parsed" }
        var result: Result<String, TMEScoringPreparation<String>.PreparationError>?
        preparation.onCompletion = { result = $0 }
        preparation.prepare(songId: "wanted") { _ in "request-empty-lrc" }
        let response = #"{"code":0,"data":{"songList":[{"songId":"wanted","songName":"test","pitchUrl":"https://example.test/pitch","lrcList":[{"type":"lrc","url":""},{"type":"lrc","url":"https://example.test/lyric"}]}]}}"#
        precondition(preparation.handleResponse(requestId: "request-empty-lrc",
                                            jsonOption: infoOption, httpCode: 200, response: response))
        waitUntil { result != nil }
        precondition((try? result?.get()) == "parsed", "must select the nonempty LRC URL")
        preparation.cancel()
    }

    private static func testDownloadAndParsingFailures() throws {
        ResourceURLProtocol.bodies = ["/pitch": Data("valid".utf8)]
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ResourceURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let response = #"{"code":0,"data":{"songList":[{"songId":"wanted","songName":"test","pitchUrl":"https://example.test/pitch","lrcList":[{"type":"lrc","url":"https://example.test/lyric"}]}]}}"#

        let preparation = TMEScoringPreparation<String>(session: session) { _, _ in "ok" }
        var completions = [Result<String, TMEScoringPreparation<String>.PreparationError>]()
        preparation.onCompletion = { completions.append($0) }
        preparation.prepare(songId: "wanted") { _ in "request-failure" }
        precondition(preparation.handleResponse(requestId: "request-failure", jsonOption: infoOption,
                                            httpCode: 200, response: response))
        waitUntil { !completions.isEmpty }
        guard case .failure(.downloadFailed) = completions[0] else { preconditionFailure("download should fail") }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        precondition(completions.count == 1)

        ResourceURLProtocol.bodies["/lyric"] = Data("valid".utf8)
        let invalidModel = TMEScoringPreparation<String>(session: session) { _, _ in nil }
        var invalidResult: Result<String, TMEScoringPreparation<String>.PreparationError>?
        invalidModel.onCompletion = { invalidResult = $0 }
        invalidModel.prepare(songId: "wanted") { _ in "request-invalid-model" }
        precondition(invalidModel.handleResponse(requestId: "request-invalid-model",
                                               jsonOption: infoOption, httpCode: 200, response: response))
        waitUntil { invalidResult != nil }
        guard case .failure(.invalidFiles) = invalidResult else { preconditionFailure("model should fail") }
    }

    private static func testCancelIgnoresLateResponse() {
        let preparation = TMEScoringPreparation<String>(parseModel: { _, _ in "model" })
        var completions = 0
        preparation.onCompletion = { _ in completions += 1 }
        preparation.prepare(songId: "wanted") { _ in "cancelled" }
        preparation.cancel()
        precondition(!preparation.handleResponse(requestId: "cancelled", jsonOption: infoOption,
                                             httpCode: 200, response: "{}"))
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        precondition(completions == 0)
    }

    private static func testCancelDuringStatusStopsOtherDownloads() {
        ResourceURLProtocol.requestedURLs = []
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ResourceURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let preparation = TMEScoringPreparation<String>(session: session) { _, _ in "parsed" }
        var statuses = [TMEScoringPreparation<String>.Status]()
        var completions = 0
        preparation.onStatus = { status in
            statuses.append(status)
            if status == .downloadingLyrics { preparation.cancel() }
        }
        preparation.onCompletion = { _ in completions += 1 }
        preparation.prepare(songId: "wanted") { _ in "request-cancel-on-status" }
        let response = #"{"code":0,"data":{"songList":[{"songId":"wanted","songName":"test","pitchUrl":"https://example.test/pitch","lrcList":[{"type":"lrc","url":"https://example.test/lyric"}]}]}}"#
        precondition(preparation.handleResponse(requestId: "request-cancel-on-status",
                                            jsonOption: infoOption, httpCode: 200, response: response))
        waitUntil { statuses.contains(.downloadingLyrics) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        precondition(statuses == [.requestingSongInfo, .downloadingLyrics],
                     "cancellation must stop further status updates")
        precondition(completions == 0)
    }

    private static func testCancelBeforeParsingSkipsModel() {
        ResourceURLProtocol.bodies = [
            "/pitch": Data("pitch".utf8),
            "/lyric": Data("lyric".utf8)
        ]
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ResourceURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        var parses = 0
        var completions = 0
        var cancelled = false
        let preparation = TMEScoringPreparation<String>(session: session) { _, _ in
            parses += 1
            return "parsed"
        }
        preparation.onStatus = { status in
            if status == .parsing {
                preparation.cancel()
                cancelled = true
            }
        }
        preparation.onCompletion = { _ in completions += 1 }
        preparation.prepare(songId: "wanted") { _ in "request-cancel-before-parse" }
        let response = #"{"code":0,"data":{"songList":[{"songId":"wanted","songName":"test","pitchUrl":"https://example.test/pitch","lrcList":[{"type":"lrc","url":"https://example.test/lyric"}]}]}}"#
        precondition(preparation.handleResponse(requestId: "request-cancel-before-parse",
                                            jsonOption: infoOption, httpCode: 200, response: response))
        waitUntil { cancelled }
        precondition(parses == 0 && completions == 0,
                     "cancelled session must not parse deleted files or complete")
    }

    private static func testOldParserCallbackCannotAffectNewSongWithReusedRequestId() {
        let preparation = TMEScoringPreparation<String>(parseModel: { _, _ in "model" })
        var completions = 0
        preparation.onCompletion = { _ in completions += 1 }
        preparation.prepare(songId: "old") { _ in "reused-id" }
        precondition(preparation.handleResponse(requestId: "reused-id", jsonOption: infoOption,
                                            httpCode: 500, response: "{}"))
        preparation.cancel()
        preparation.prepare(songId: "new") { _ in "reused-id" }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        precondition(completions == 0, "old parser callback must not fail a new song")
        preparation.cancel()
    }

    private static let infoOption = #"{"vendorId":2,"actionType":"song-info","actionParameter":{"songIdListStr":"wanted"}}"#

    private static func waitUntil(_ done: () -> Bool) {
        let deadline = Date().addingTimeInterval(5)
        while !done() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        precondition(done(), "preparation timed out")
    }

    private static func require<T>(_ value: T?) throws -> T {
        guard let value = value else { throw NSError(domain: "TMEScoringPreparationTests", code: 1) }
        return value
    }
}
