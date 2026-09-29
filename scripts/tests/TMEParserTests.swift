import Foundation

final class Probe: TMEParserDelegate {
    var events: [String] = []
    var errors: [(String, String, String, TMEParseError)] = []

    private func record(_ id: String, _ action: String) {
        precondition(Thread.isMainThread)
        events.append("\(id):\(action)")
    }

    func onSongs(_ id: String, result: TMESongsResult) {
        if id == "0" {
            precondition(result.songList.first?.album?.imagePathMapList?.first?.key == "cover")
            precondition(result.nextQueryInfo == "next")
        }
        if id == "empty" { precondition(result.songList.isEmpty) }
        if id == "minimal" {
            precondition(result.songList.first?.songId == "s2")
            precondition(result.songList.first?.album == nil)
        }
        record(id, "songs")
    }

    func onSearchSongs(_ id: String, result: TMESearchSongsResult) {
        precondition(result.total == 1)
        record(id, "search-song")
    }

    func onSongInfo(_ id: String, result: TMESongInfoResult) {
        precondition(result.songList.first?.songId == "s1")
        record(id, "song-info")
    }

    func onSongUrl(_ id: String, result: TMESongUrlResult) {
        precondition(result.mediaList.first?.expire == "2021-08-13 18:13:41")
        precondition(result.mediaList.first?.url == "https://example.com/a.mkv?sign=1")
        record(id, "song-url")
    }

    func onSonglistPage(_ id: String, result: TMEPageResult) {
        precondition(result.list.first?.title == "榜单")
        record(id, "songlist-page")
    }

    func onSonglistDetail(_ id: String, result: TMEDetailResult) {
        precondition(result.songList.first?.songId == "s1")
        record(id, "songlist-detail")
    }

    func onRanklistPage(_ id: String, result: TMEPageResult) {
        precondition(result.total == 1)
        record(id, "ranklist-page")
    }

    func onRanklistDetail(_ id: String, result: TMEDetailResult) {
        precondition(result.code == "p1")
        record(id, "ranklist-detail")
    }

    func onParseError(_ id: String, jsonOption: String, responseBody: String,
                      error: TMEParseError) {
        precondition(Thread.isMainThread)
        errors.append((id, jsonOption, responseBody, error))
    }
}

@main
struct TMEParserTests {
    static func waitUntil(_ done: () -> Bool) {
        let deadline = Date().addingTimeInterval(5)
        while !done() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        precondition(done(), "parser callback timed out")
    }

    static func main() {
        let probe = Probe()
        let parser = TMEParser()
        parser.delegate = probe
        let song = #"{"songId":"s1","songName":"要强","album":{"imagePathMapList":[{"key":"cover","value":"https://example.com"}]}}"#
        let songs = "{\"code\":0,\"data\":{\"songList\":[\(song)],\"nextQueryInfo\":\"next\"}}"
        let search = "{\"code\":0,\"data\":{\"total\":1,\"songList\":[\(song)]}}"
        let info = "{\"code\":0,\"data\":{\"songList\":[\(song)]}}"
        let url = #"{"code":0,"data":{"mediaList":[{"fileType":"mkv","url":"https://example.com/a.mkv?sign=1","expire":"2021-08-13 18:13:41"}]}}"#
        let page = #"{"code":0,"data":{"total":1,"list":[{"code":"p1","title":"榜单","status":1}]}}"#
        let detail = #"{"code":0,"data":{"code":"p1","title":"榜单","songList":[{"songId":"s1"}]}}"#
        let samples = [("songs", songs), ("search-song", search), ("song-info", info),
                       ("song-url", url), ("songlist-page", page), ("songlist-detail", detail),
                       ("ranklist-page", page), ("ranklist-detail", detail)]
        for (index, sample) in samples.enumerated() {
            parser.parse(requestId: "\(index)",
                         jsonOption: "{\"vendorId\":2,\"actionType\":\"\(sample.0)\"}",
                         httpCode: 200, responseBody: sample.1)
        }
        precondition(probe.events.isEmpty)
        waitUntil { probe.events.count == samples.count }
        precondition(probe.events == samples.enumerated().map { "\($0.offset):\($0.element.0)" })

        let valid = #"{"vendorId":2,"actionType":"songs"}"#
        let failures: [(String, String, Int, String, TMEParseError)] = [
            ("bad-json", "not json", 200, songs, .invalidRequest),
            ("bad-vendor", #"{"vendorId":3,"actionType":"songs"}"#, 200, songs, .invalidRequest),
            ("unknown", #"{"vendorId":2,"actionType":"other"}"#, 200, songs, .unsupportedAction("other")),
            ("http", valid, 503, songs, .httpStatus(503)),
            ("api", valid, 200, #"{"code":5,"msg":"denied"}"#, .apiError(5, "denied")),
            ("api-with-partial-data", valid, 200,
             #"{"code":5,"msg":"denied","data":{"other":"value"}}"#, .apiError(5, "denied")),
            ("malformed", valid, 200, "not json", .invalidResponse),
            ("wrong-type", valid, 200, #"{"code":0,"data":{"songList":"wrong"}}"#, .invalidResponse),
            ("missing-data", valid, 200, #"{"code":0}"#, .invalidResponse),
            ("missing-action", #"{"vendorId":2}"#, 200, songs, .invalidRequest)
        ]
        for failure in failures {
            parser.parse(requestId: failure.0, jsonOption: failure.1,
                         httpCode: failure.2, responseBody: failure.3)
        }
        precondition(probe.errors.isEmpty)
        waitUntil { probe.errors.count == failures.count }
        for (received, expected) in zip(probe.errors, failures) {
            precondition(received.0 == expected.0 && received.1 == expected.1)
            precondition(received.2 == expected.3 && received.3 == expected.4)
        }
        precondition(probe.events.count == samples.count)

        parser.parse(requestId: "empty", jsonOption: valid, httpCode: 200,
                     responseBody: #"{"code":0,"data":{"songList":[]}}"#)
        parser.parse(requestId: "minimal", jsonOption: valid, httpCode: 200,
                     responseBody: #"{"code":0,"data":{"songList":[{"songId":"s2","songName":"简版"}]}}"#)
        precondition(probe.events.count == samples.count)
        waitUntil { probe.events.count == samples.count + 2 }
        precondition(Array(probe.events.suffix(2)) == ["empty:songs", "minimal:songs"])

        do {
            let transientParser = TMEParser()
            transientParser.delegate = probe
            transientParser.parse(requestId: "transient", jsonOption: valid, httpCode: 200,
                                  responseBody: #"{"code":0,"data":{"songList":[]}}"#)
        }
        waitUntil { probe.events.count == samples.count + 3 }
        precondition(probe.events.last == "transient:songs")
        print("TMEParserTests passed")
    }
}
