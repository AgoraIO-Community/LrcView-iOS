# TME Response Parser Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 iOS Demo 实现八种 `sendExtRequest` 响应的异步、强类型解析和主线程回调，同时保持现有歌曲列表 UI 行为。

**Architecture:** `TMEParser` 在专用串行队列按 `jsonOption.actionType` 解码，主队列异步调用 `TMEParserDelegate`。`TmeManager` 仅转交 SDK 回调，并用请求 ID 过滤过期成功/失败事件；Android 只遵循已批准设计中的对等契约，本次不写 Android 代码。

**Tech Stack:** Swift 5、Foundation `JSONDecoder`、GCD、UIKit Demo、独立 `swiftc` 测试程序。

---

设计依据：`docs/superpowers/specs/2026-09-29-tme-response-parser-design.md`。工作区已有未提交的 Demo 和 Xcode 工程改动；执行时保留所有原有内容，提交操作不得意外纳入它们。以下命令均从 `LrcView-iOS` 目录执行。

## 文件边界

- 新增 `Demo/Demo/Other/Utils/TMEParserModels.swift`：歌曲嵌套结构、八类响应复用的数据模型、通用业务响应封装。
- 修改 `Demo/Demo/Other/Utils/TmeSongCatalog.swift`：现有同步接口改用共享歌曲模型，保持最多六首的旧行为。
- 新增 `Demo/Demo/Other/Utils/TMEParser.swift`：请求分派、错误类型、专用串行解析队列及主线程委托分发。
- 新增 `Demo/Demo/Other/Utils/TMEResponseTracker.swift`：独立测试的请求 ID 有效性门闩。
- 修改 `Demo/Demo/Other/Utils/TmeManager.swift`：连接 SDK 回包与解析器，保留现有轻量歌曲展示和 UI 委托。
- 修改 `Demo/Demo.xcodeproj/project.pbxproj`：仅为新增三个 Swift 文件添加引用和 Sources 条目。
- 新增 `scripts/tests/TMEParserTests.swift` 和 `scripts/tests/TMEResponseTrackerTests.swift`：无 SDK、无网络测试；保留原 `scripts/tests/TmeSongCatalogTests.swift`。

### Task 1: 共享歌曲及响应模型

**Files:**
- Create: `Demo/Demo/Other/Utils/TMEParserModels.swift`
- Modify: `Demo/Demo/Other/Utils/TmeSongCatalog.swift`
- Test: `scripts/tests/TmeSongCatalogTests.swift`

- [ ] **Step 1: 写失败的共享模型测试。** 在 `TmeSongCatalogTests.main()` 的 `print("TmeSongCatalogTests passed")` 前加入：

```swift
let detailed = """
{"code":0,"data":{"songList":[{"songId":"s1","songName":"要强","version":"",
"duration":220,"status":1,"sequence":8,"grantStatus":1,
"grantStartTime":"2022-06-15 00:00:00","publicTime":"2004-09-15 00:00:00",
"language":"普通话","genre":"POP","grantedAreaCodes":["CN"],
"pitchUrl":"https://example.com/pitch.txt","chorusStartMS":21923,"chorusEndMS":42983,
"copyrightList":[{"sceneId":"1","terminalIdList":["1","2"]}],
"album":{"albumId":"a1","albumName":"专辑","imagePathMapList":[{"key":"cover","value":"https://example.com/a.jpg"}]},
"artistList":[{"artistId":"r1","artistName":"歌手"}],
"lrcList":[{"type":"lrc","url":"https://example.com/a.lrc"}]}]}}
"""
let decoded = try JSONDecoder().decode(TMEAPIEnvelope<TMESongsResult>.self, from: Data(detailed.utf8))
precondition(decoded.data?.songList.first?.album?.imagePathMapList?.first?.key == "cover")
precondition(decoded.data?.songList.first?.lrcList?.first?.url == "https://example.com/a.lrc")
precondition(decoded.data?.songList.first?.copyrightList?.first?.terminalIdList == ["1", "2"])
precondition(decoded.data?.songList.first?.chorusStartMS == 21923)
precondition(decoded.data?.songList.first?.grantedAreaCodes == ["CN"])
precondition(decoded.data?.songList.first?.duration == 220)
let mapped = try TmeSongCatalog.parse(response: detailed, httpCode: 200)
precondition(mapped.first?.artist == "歌手")
do {
    let failure = #"{"code":1,"msg":"denied","data":{"other":"value"}}"#
    _ = try TmeSongCatalog.parse(response: failure, httpCode: 200)
    fatalError("Business error must take precedence over invalid data")
} catch TmeSongCatalog.ParseError.apiError(1, "denied") {}
```

- [ ] **Step 2: 确认测试因新模型不存在而失败。** Run: `swiftc -module-cache-path /private/tmp/klyrics-tme-module-cache -o /private/tmp/klyrics-catalog-tests Demo/Demo/Other/Utils/TmeSongCatalog.swift scripts/tests/TmeSongCatalogTests.swift`；期望 `cannot find 'TMEAPIEnvelope' in scope`。
- [ ] **Step 3: 创建模型。** `TMEParserModels.swift` 内容如下（`Decodable` 的默认键名保持与回包一致）：

```swift
import Foundation

struct TMEAPIEnvelope<DataType: Decodable>: Decodable {
    let code: Int
    let msg: String?
    let data: DataType?
}

struct TMEAPIStatus: Decodable {
    let code: Int
    let msg: String?
}

struct TMEImagePath: Decodable { let key: String; let value: String }
struct TMEAlbum: Decodable {
    let albumId: String?
    let albumName: String?
    let imagePathMapList: [TMEImagePath]?
}
struct TMEArtist: Decodable { let artistId: String?; let artistName: String? }
struct TMELyric: Decodable { let type: String; let url: String }
struct TMECopyright: Decodable { let sceneId: String; let terminalIdList: [String] }

struct TMESongDetail: Decodable {
    let songId: String
    let songName: String
    let version: String?
    let duration: Int?
    let status: Int?
    let sequence: Int?
    let grantStatus: Int?
    let grantStartTime: String?
    let publicTime: String?
    let language: String?
    let genre: String?
    let grantedAreaCodes: [String]?
    let pitchUrl: String?
    let chorusStartMS: Int?
    let chorusEndMS: Int?
    let copyrightList: [TMECopyright]?
    let album: TMEAlbum?
    let artistList: [TMEArtist]?
    let lrcList: [TMELyric]?
}

struct TMESongsResult: Decodable {
    let songList: [TMESongDetail]
    let nextQueryInfo: String?
}
struct TMESearchSongsResult: Decodable { let total: Int; let songList: [TMESongDetail] }
struct TMESongInfoResult: Decodable { let songList: [TMESongDetail] }
struct TMEMedia: Decodable { let fileType: String; let url: String; let expire: String }
struct TMESongUrlResult: Decodable { let mediaList: [TMEMedia] }
struct TMEPageItem: Decodable {
    let code: String
    let title: String
    let description: String?
    let url: String?
    let status: Int?
}
struct TMEPageResult: Decodable { let total: Int; let list: [TMEPageItem] }
struct TMESongReference: Decodable { let songId: String }
struct TMEDetailResult: Decodable {
    let code: String
    let title: String
    let description: String?
    let status: Int?
    let imgUrl: String?
    let songList: [TMESongReference]
}
```

将 `TmeSongCatalog.swift` 改为以下完整内容，保留旧 HTTP / API 错误和六首歌曲限制：

```swift
import Foundation

struct TmeSong {
    let id: String
    let name: String
    let artist: String
}

enum TmeSongCatalog {
    enum ParseError: Error, Equatable {
        case httpStatus(Int)
        case apiError(Int, String)
        case invalidResponse
    }

    static func parse(response: String, httpCode: Int) throws -> [TmeSong] {
        guard (200..<300).contains(httpCode) else {
            throw ParseError.httpStatus(httpCode)
        }
        let source = Data(response.utf8)
        guard let status = try? JSONDecoder().decode(TMEAPIStatus.self, from: source) else {
            throw ParseError.invalidResponse
        }
        guard status.code == 0 else {
            throw ParseError.apiError(status.code, status.msg ?? "Unknown error")
        }
        guard let body = try? JSONDecoder().decode(TMEAPIEnvelope<TMESongsResult>.self,
                                                   from: source),
              let data = body.data else {
            throw ParseError.invalidResponse
        }
        return Array(data.songList.filter { !$0.songId.isEmpty }.prefix(6)).map {
            TmeSong(id: $0.songId, name: $0.songName,
                    artist: $0.artistList?.first?.artistName ?? "")
        }
    }
}
```
- [ ] **Step 4: 运行旧测试和新增断言。** Run: `swiftc -module-cache-path /private/tmp/klyrics-tme-module-cache -o /private/tmp/klyrics-catalog-tests Demo/Demo/Other/Utils/TMEParserModels.swift Demo/Demo/Other/Utils/TmeSongCatalog.swift scripts/tests/TmeSongCatalogTests.swift`，再运行 `/private/tmp/klyrics-catalog-tests`；期望 `TmeSongCatalogTests passed`。
- [ ] **Step 5: 仅在不包含原有未提交文件的情况下提交新增模型。** Run: `git add -- Demo/Demo/Other/Utils/TMEParserModels.swift`，然后 `git commit --only -m 'feat: define TME response models' -- Demo/Demo/Other/Utils/TMEParserModels.swift`；不要将现有未跟踪的 `TmeSongCatalog.swift` 或其测试文件加入提交。

### Task 2: 八种响应的异步解析与回调

**Files:**
- Create: `Demo/Demo/Other/Utils/TMEParser.swift`
- Create: `scripts/tests/TMEParserTests.swift`

- [ ] **Step 1: 先写可执行的失败测试。** `scripts/tests/TMEParserTests.swift` 内容如下；所有输入均为有效 JSON 字符串，无需连接 SDK：

```swift
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
        }
        if id == "empty" { precondition(result.songList.isEmpty) }
        if id == "minimal" {
            precondition(result.songList.first?.songId == "s2")
            precondition(result.songList.first?.album == nil)
        }
        record(id, "songs")
    }
    func onSearchSongs(_ id: String, result: TMESearchSongsResult) {
        precondition(result.total == 1); record(id, "search-song")
    }
    func onSongInfo(_ id: String, result: TMESongInfoResult) { record(id, "song-info") }
    func onSongUrl(_ id: String, result: TMESongUrlResult) {
        precondition(result.mediaList.first?.expire == "2021-08-13 18:13:41")
        record(id, "song-url")
    }
    func onSonglistPage(_ id: String, result: TMEPageResult) { record(id, "songlist-page") }
    func onSonglistDetail(_ id: String, result: TMEDetailResult) { record(id, "songlist-detail") }
    func onRanklistPage(_ id: String, result: TMEPageResult) { record(id, "ranklist-page") }
    func onRanklistDetail(_ id: String, result: TMEDetailResult) { record(id, "ranklist-detail") }
    func onParseError(_ id: String, jsonOption: String, responseBody: String, error: TMEParseError) {
        precondition(Thread.isMainThread)
        errors.append((id, jsonOption, responseBody, error))
    }
}

@main struct TMEParserTests {
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
            parser.parse(requestId: "\(index)", jsonOption: "{\"vendorId\":2,\"actionType\":\"\(sample.0)\"}",
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
```

- [ ] **Step 2: 确认缺少解析器导致编译失败。** Run: `swiftc -module-cache-path /private/tmp/klyrics-tme-module-cache -o /private/tmp/klyrics-parser-tests Demo/Demo/Other/Utils/TMEParserModels.swift scripts/tests/TMEParserTests.swift`；期望 `cannot find type 'TMEParserDelegate' in scope`。
- [ ] **Step 3: 实现分派、错误和委托。** `TMEParser.swift` 提供以下完整接口和分派逻辑：

```swift
import Foundation

enum TMEParseError: Error, Equatable {
    case invalidRequest
    case unsupportedAction(String)
    case httpStatus(Int)
    case apiError(Int, String?)
    case invalidResponse
}

protocol TMEParserDelegate: AnyObject {
    func onSongs(_ requestId: String, result: TMESongsResult)
    func onSearchSongs(_ requestId: String, result: TMESearchSongsResult)
    func onSongInfo(_ requestId: String, result: TMESongInfoResult)
    func onSongUrl(_ requestId: String, result: TMESongUrlResult)
    func onSonglistPage(_ requestId: String, result: TMEPageResult)
    func onSonglistDetail(_ requestId: String, result: TMEDetailResult)
    func onRanklistPage(_ requestId: String, result: TMEPageResult)
    func onRanklistDetail(_ requestId: String, result: TMEDetailResult)
    func onParseError(_ requestId: String, jsonOption: String, responseBody: String,
                      error: TMEParseError)
}

extension TMEParserDelegate {
    func onSongs(_ requestId: String, result: TMESongsResult) {}
    func onSearchSongs(_ requestId: String, result: TMESearchSongsResult) {}
    func onSongInfo(_ requestId: String, result: TMESongInfoResult) {}
    func onSongUrl(_ requestId: String, result: TMESongUrlResult) {}
    func onSonglistPage(_ requestId: String, result: TMEPageResult) {}
    func onSonglistDetail(_ requestId: String, result: TMEDetailResult) {}
    func onRanklistPage(_ requestId: String, result: TMEPageResult) {}
    func onRanklistDetail(_ requestId: String, result: TMEDetailResult) {}
}

private struct TMERequestOption: Decodable {
    let vendorId: Int
    let actionType: String
}

private enum TMEParsedResponse {
    case songs(TMESongsResult)
    case searchSongs(TMESearchSongsResult)
    case songInfo(TMESongInfoResult)
    case songUrl(TMESongUrlResult)
    case songlistPage(TMEPageResult)
    case songlistDetail(TMEDetailResult)
    case ranklistPage(TMEPageResult)
    case ranklistDetail(TMEDetailResult)
}

final class TMEParser {
    weak var delegate: TMEParserDelegate?
    private let queue = DispatchQueue(label: "com.klyrics.tme.parser", qos: .userInitiated)

    func parse(requestId: String, jsonOption: String, httpCode: Int, responseBody: String) {
        queue.async { [self] in
            let parsed = Self.decode(jsonOption: jsonOption, httpCode: httpCode,
                                     responseBody: responseBody)
            DispatchQueue.main.async { [self] in
                guard let delegate = delegate else { return }
                switch parsed {
                case .failure(let error):
                    delegate.onParseError(requestId, jsonOption: jsonOption,
                                          responseBody: responseBody, error: error)
                case .success(let value):
                    switch value {
                    case .songs(let result): delegate.onSongs(requestId, result: result)
                    case .searchSongs(let result): delegate.onSearchSongs(requestId, result: result)
                    case .songInfo(let result): delegate.onSongInfo(requestId, result: result)
                    case .songUrl(let result): delegate.onSongUrl(requestId, result: result)
                    case .songlistPage(let result): delegate.onSonglistPage(requestId, result: result)
                    case .songlistDetail(let result): delegate.onSonglistDetail(requestId, result: result)
                    case .ranklistPage(let result): delegate.onRanklistPage(requestId, result: result)
                    case .ranklistDetail(let result): delegate.onRanklistDetail(requestId, result: result)
                    }
                }
            }
        }
    }

    private static func body<T: Decodable>(_ type: T.Type, response: String) throws -> T {
        let source = Data(response.utf8)
        guard let status = try? JSONDecoder().decode(TMEAPIStatus.self, from: source) else {
            throw TMEParseError.invalidResponse
        }
        guard status.code == 0 else {
            throw TMEParseError.apiError(status.code, status.msg)
        }
        guard let envelope = try? JSONDecoder().decode(TMEAPIEnvelope<T>.self,
                                                        from: source),
              let value = envelope.data else {
            throw TMEParseError.invalidResponse
        }
        return value
    }

    private static func decode(jsonOption: String, httpCode: Int,
                               responseBody: String) -> Result<TMEParsedResponse, TMEParseError> {
        guard let request = try? JSONDecoder().decode(TMERequestOption.self,
                                                       from: Data(jsonOption.utf8)),
              request.vendorId == 2 else { return .failure(.invalidRequest) }
        let action = request.actionType
        let actions = ["songs", "search-song", "song-info", "song-url", "songlist-page",
                       "songlist-detail", "ranklist-page", "ranklist-detail"]
        guard actions.contains(action) else { return .failure(.unsupportedAction(action)) }
        guard (200..<300).contains(httpCode) else { return .failure(.httpStatus(httpCode)) }
        do {
            switch action {
            case "songs": return .success(.songs(try body(TMESongsResult.self, response: responseBody)))
            case "search-song": return .success(.searchSongs(try body(TMESearchSongsResult.self, response: responseBody)))
            case "song-info": return .success(.songInfo(try body(TMESongInfoResult.self, response: responseBody)))
            case "song-url": return .success(.songUrl(try body(TMESongUrlResult.self, response: responseBody)))
            case "songlist-page": return .success(.songlistPage(try body(TMEPageResult.self, response: responseBody)))
            case "songlist-detail": return .success(.songlistDetail(try body(TMEDetailResult.self, response: responseBody)))
            case "ranklist-page": return .success(.ranklistPage(try body(TMEPageResult.self, response: responseBody)))
            case "ranklist-detail": return .success(.ranklistDetail(try body(TMEDetailResult.self, response: responseBody)))
            default: return .failure(.unsupportedAction(action))
            }
        } catch let error as TMEParseError {
            return .failure(error)
        } catch {
            return .failure(.invalidResponse)
        }
    }
}
```

- [ ] **Step 4: 编译并运行测试。** Run: `swiftc -module-cache-path /private/tmp/klyrics-tme-module-cache -o /private/tmp/klyrics-parser-tests Demo/Demo/Other/Utils/TMEParserModels.swift Demo/Demo/Other/Utils/TMEParser.swift scripts/tests/TMEParserTests.swift`，再运行 `/private/tmp/klyrics-parser-tests`；期望 `TMEParserTests passed`，包含空列表、可选字段、缺少 `data` 和缺少 `actionType` 的样例。
- [ ] **Step 5: 仅提交本任务新增文件。** Run: `git add -- Demo/Demo/Other/Utils/TMEParser.swift scripts/tests/TMEParserTests.swift`，然后 `git commit --only -m 'feat: parse TME responses asynchronously' -- Demo/Demo/Other/Utils/TMEParser.swift scripts/tests/TMEParserTests.swift`。

### Task 3: 请求 ID 过滤并接入 Demo

**Files:**
- Create: `Demo/Demo/Other/Utils/TMEResponseTracker.swift`
- Create: `scripts/tests/TMEResponseTrackerTests.swift`
- Modify: `Demo/Demo/Other/Utils/TmeManager.swift`
- Modify: `Demo/Demo.xcodeproj/project.pbxproj`

- [ ] **Step 1: 写失败的旧请求测试。** `TMEResponseTrackerTests.swift`：

```swift
import Foundation

@main struct TMEResponseTrackerTests {
    static func main() {
        let tracker = TMEResponseTracker()
        tracker.set("old")
        tracker.set("new")
        precondition(!tracker.consume("old")) // 旧成功回调不得生效
        precondition(!tracker.consume("old")) // 旧错误回调不得生效
        precondition(tracker.consume("new"))
        precondition(!tracker.consume("new"))
        tracker.set("cancelled")
        tracker.clear()
        precondition(!tracker.consume("cancelled"))
        var deliveries: [String] = []
        tracker.set("success")
        tracker.deliverIfCurrent("success") { _ in deliveries.append("success") }
        precondition(deliveries == ["success"])
        tracker.set("old")
        tracker.set("new")
        tracker.deliverIfCurrent("old") { _ in deliveries.append("stale") }
        precondition(deliveries == ["success"])
        tracker.deliverIfCurrent("new") { _ in deliveries.append("error") }
        precondition(deliveries == ["success", "error"])
        tracker.set("reentrant")
        tracker.deliverIfCurrent("reentrant") { isStillCurrent in
            deliveries.append("load")
            tracker.set("retry")
            if isStillCurrent() { deliveries.append("old-status") }
        }
        precondition(deliveries == ["success", "error", "load"])
        tracker.set("stopping")
        tracker.deliverIfCurrent("stopping") { isStillCurrent in
            tracker.clear()
            precondition(!isStillCurrent())
        }
        print("TMEResponseTrackerTests passed")
    }
}
```

- [ ] **Step 2: 确认因缺少 tracker 而失败。** Run: `swiftc -parse-as-library -module-cache-path /private/tmp/klyrics-tme-module-cache -o /private/tmp/klyrics-tracker-tests scripts/tests/TMEResponseTrackerTests.swift`；单个包含 `@main` 的 Swift 文件需要 `-parse-as-library`，期望 `cannot find 'TMEResponseTracker' in scope`。
- [ ] **Step 3: 新增可独立编译的门闩。** `TMEResponseTracker.swift`：

```swift
import Foundation

final class TMEResponseTracker {
    private var currentRequestId: String?
    private var generation = 0

    func set(_ requestId: String) {
        generation &+= 1
        currentRequestId = requestId
    }
    func clear() {
        generation &+= 1
        currentRequestId = nil
    }

    func consume(_ requestId: String) -> Bool {
        guard currentRequestId == requestId else { return false }
        currentRequestId = nil
        return true
    }

    func deliverIfCurrent(_ requestId: String, _ deliver: (() -> Bool) -> Void) {
        guard consume(requestId) else { return }
        let acceptedGeneration = generation
        deliver { [self] in generation == acceptedGeneration }
    }
}
```

- [ ] **Step 4: 验证门闩。** Run: `swiftc -module-cache-path /private/tmp/klyrics-tme-module-cache -o /private/tmp/klyrics-tracker-tests Demo/Demo/Other/Utils/TMEResponseTracker.swift scripts/tests/TMEResponseTrackerTests.swift`，再运行 `/private/tmp/klyrics-tracker-tests`；期望 `TMEResponseTrackerTests passed`。
- [ ] **Step 5: 连接 `TmeManager`。** 将 `private var songsRequestId: String?` 替换为 `private let songsRequest = TMEResponseTracker()`，增加 `private let responseParser = TMEParser()` 及初始化委托：

```swift
override init() {
    super.init()
    responseParser.delegate = self
}
```

`requestSongs()` 开始发送前执行 `songsRequest.clear()`，拿到非空 ID 后执行 `songsRequest.set(requestId)`；`stop()` 中执行 `songsRequest.clear()`。以如下代码替换原有 `onExtResponse` 主线程解码块，并让管理器实现解析委托：

```swift
func onExtResponse(_ requestId: String, jsonOption: String, httpCode: Int, response: String) {
    responseParser.parse(requestId: requestId, jsonOption: jsonOption,
                         httpCode: httpCode, responseBody: response)
}

// 位于 extension TmeManager: TMEParserDelegate 中
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
```

不把 `jsonOption` 或 `responseBody` 写入日志或错误提示。在 `Demo.xcodeproj/project.pbxproj` 的四个对应区块中分别加入以下完整条目，不改动原有条目：

```text
/* PBXBuildFile */
A0C00000000000000000000A /* TMEParserModels.swift in Sources */ = {isa = PBXBuildFile; fileRef = A0C000000000000000000009 /* TMEParserModels.swift */; };
A0C00000000000000000000C /* TMEParser.swift in Sources */ = {isa = PBXBuildFile; fileRef = A0C00000000000000000000B /* TMEParser.swift */; };
A0C00000000000000000000E /* TMEResponseTracker.swift in Sources */ = {isa = PBXBuildFile; fileRef = A0C00000000000000000000D /* TMEResponseTracker.swift */; };

/* PBXFileReference */
A0C000000000000000000009 /* TMEParserModels.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TMEParserModels.swift; sourceTree = "<group>"; };
A0C00000000000000000000B /* TMEParser.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TMEParser.swift; sourceTree = "<group>"; };
A0C00000000000000000000D /* TMEResponseTracker.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TMEResponseTracker.swift; sourceTree = "<group>"; };

/* Utils PBXGroup children */
A0C000000000000000000009 /* TMEParserModels.swift */,
A0C00000000000000000000B /* TMEParser.swift */,
A0C00000000000000000000D /* TMEResponseTracker.swift */,

/* Sources PBXSourcesBuildPhase files */
A0C00000000000000000000A /* TMEParserModels.swift in Sources */,
A0C00000000000000000000C /* TMEParser.swift in Sources */,
A0C00000000000000000000E /* TMEResponseTracker.swift in Sources */,
```
- [ ] **Step 6: 全量验证。** 运行三个独立 Swift 测试程序、`bash scripts/tests/tme_sdk_flow.sh`、`plutil -lint Demo/Demo.xcodeproj/project.pbxproj`、`git diff --check`。如具备模拟器依赖，还运行 `xcodebuild -workspace Demo/Demo.xcworkspace -scheme Demo -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/klyrics-tme-parser-workspace-derived CODE_SIGNING_ALLOWED=NO -quiet build`；CocoaPods 提供的 `AgoraRtcKit` 必须通过 workspace 一并构建。若缺少 `localConfig.swift` 或 Pods，记录实际阻碍，不创建或更改真实凭据文件。
- [ ] **Step 7: 仅提交本任务新增文件。** Run: `git add -- Demo/Demo/Other/Utils/TMEResponseTracker.swift scripts/tests/TMEResponseTrackerTests.swift`，然后 `git commit --only -m 'test: protect TME callbacks from stale requests' -- Demo/Demo/Other/Utils/TMEResponseTracker.swift scripts/tests/TMEResponseTrackerTests.swift`。`TmeManager.swift`、`TmeSongCatalog.swift` 和 `project.pbxproj` 当前包含用户尚未提交的工作，保留其工作区状态，不在无明确授权时把整个文件提交。
