# Download Temporary File Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every iOS lyric download a fresh, isolated operation that cannot append to an old ZIP and always releases temporary files and manager state.

**Architecture:** Introduce a small Foundation-only `DownloadTemporaryFile` owner for a unique per-request directory and non-appending output stream. `Downloader` owns it until a successful callback transfers the path; `LyricsFileDownloader` then consumes and removes it. Cache filename mapping and manager failure cleanup remain in their current layers.

**Tech Stack:** Swift 5, Foundation `URLSession` and `OutputStream`, XCTest, Zip 2.1.2, iOS 10+

---

## File Map

- Create `AgoraLyricsScore/Class/Downloader/DownloadTemporaryFile.swift`: Own one task directory, stream, writes, and cleanup.
- Create `AgoraLyricsScore/Tests/TestDownload/TestDownloadTemporaryFile.swift`: Network-independent tests for fresh writes and isolation.
- Modify `AgoraLyricsScore/Class/Downloader/Downloader.swift`: Use the temporary-file owner and clean it on failure/cancellation.
- Modify `AgoraLyricsScore/Class/Downloader/DownloaderManager.swift`: Release URL state after failures and allow factory injection for testing.
- Modify `AgoraLyricsScore/Class/Downloader/Extentions.swift`: Resolve the download root through `FileManager.default.temporaryDirectory` and safely remove task output.
- Modify `AgoraLyricsScore/Class/Downloader/LyricsFileDownloader.swift`: Resolve ZIP cache names and clean transferred temporary files.
- Create `AgoraLyricsScore/Tests/TestDownload/TestDownloadLifecycle.swift`: Test cache-name mapping, transferred-file cleanup, and manager retry behavior.

### Task 1: Isolated Fresh Temporary Files

**Files:**
- Create: `AgoraLyricsScore/Class/Downloader/DownloadTemporaryFile.swift`
- Create: `AgoraLyricsScore/Tests/TestDownload/TestDownloadTemporaryFile.swift`
- Modify: `AgoraLyricsScore/Class/Downloader/Extentions.swift:32-35`

- [ ] **Step 1: Write failing tests for overwrite and isolation**

Add tests that inject a test root so they never touch the application's real temporary directory:

```swift
import XCTest
@testable import AgoraLyricsScore

final class TestDownloadTemporaryFile: XCTestCase {
    private var rootURL: URL!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgoraLyricsScoreTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: rootURL,
                                                withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: rootURL)
    }

    func testOpenStartsWithEmptyFile() throws {
        let temporaryFile = try DownloadTemporaryFile(filename: "lyrics.zip",
                                                      rootURL: rootURL,
                                                      identifier: "request")
        try Data("old".utf8).write(to: temporaryFile.fileURL)
        try temporaryFile.open()
        try temporaryFile.write(Data("new".utf8))
        temporaryFile.close()

        XCTAssertEqual(try Data(contentsOf: temporaryFile.fileURL), Data("new".utf8))
    }

    func testSameFilenameUsesDifferentTaskDirectories() throws {
        let first = try DownloadTemporaryFile(filename: "lyrics.zip", rootURL: rootURL)
        let second = try DownloadTemporaryFile(filename: "lyrics.zip", rootURL: rootURL)

        XCTAssertNotEqual(first.directoryURL, second.directoryURL)
        XCTAssertNotEqual(first.fileURL, second.fileURL)
    }

    func testRemoveDeletesWholeTaskDirectory() throws {
        let temporaryFile = try DownloadTemporaryFile(filename: "lyrics.zip", rootURL: rootURL)
        try temporaryFile.open()
        try temporaryFile.write(Data("partial".utf8))
        try temporaryFile.remove()

        XCTAssertFalse(FileManager.default.fileExists(atPath: temporaryFile.directoryURL.path))
    }
}
```

- [ ] **Step 2: Run the focused test and verify the red state**

Run the pod test scheme when generated:

```bash
xcodebuild test -workspace Demo/Demo.xcworkspace -scheme AgoraLyricsScore-Unit-Tests -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath /tmp/LrcViewDerivedData
```

Expected: compilation fails because `DownloadTemporaryFile` does not exist. In the current checkout, CocoaPods is absent, so record that infrastructure failure and additionally compile a temporary Foundation harness after Step 3.

- [ ] **Step 3: Implement the temporary-file owner and root URL**

Add a Foundation-only owner with this interface and behavior:

```swift
import Foundation

enum DownloadTemporaryFileError: Error {
    case createOutputStreamFailed
    case outputStreamNotOpen
    case writeFailed
}

final class DownloadTemporaryFile {
    let directoryURL: URL
    let fileURL: URL

    private let fileManager: FileManager
    private var outputStream: OutputStream?

    init(filename: String,
         rootURL: URL = .lyricsDownloadDirectory,
         identifier: String = UUID().uuidString,
         fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        directoryURL = rootURL.appendingPathComponent(identifier, isDirectory: true)
        fileURL = directoryURL.appendingPathComponent(filename, isDirectory: false)
        try fileManager.createDirectory(at: directoryURL,
                                        withIntermediateDirectories: true,
                                        attributes: nil)
    }

    func open() throws {
        close()
        guard let stream = OutputStream(url: fileURL, append: false) else {
            throw DownloadTemporaryFileError.createOutputStreamFailed
        }
        outputStream = stream
        stream.open()
    }

    func write(_ data: Data) throws {
        guard let stream = outputStream else {
            throw DownloadTemporaryFileError.outputStreamNotOpen
        }
        try data.withUnsafeBytes { rawBuffer in
            guard var pointer = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
            var remaining = rawBuffer.count
            while remaining > 0 {
                let written = stream.write(pointer, maxLength: remaining)
                guard written > 0 else {
                    throw stream.streamError ?? DownloadTemporaryFileError.writeFailed
                }
                pointer = pointer.advanced(by: written)
                remaining -= written
            }
        }
    }

    func close() {
        outputStream?.close()
        outputStream = nil
    }

    func remove() throws {
        close()
        if fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.removeItem(at: directoryURL)
        }
    }
}
```

Add the standard directory URL while retaining the existing misspelled path API for source compatibility:

```swift
extension URL {
    static var lyricsDownloadDirectory: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("LyricDownloadFiles", isDirectory: true)
    }
}

static func downloadedFloderPath() -> String {
    URL.lyricsDownloadDirectory.path
}
```

- [ ] **Step 4: Run the focused tests or Foundation harness and verify green**

Expected: the existing file contains only `new`, same filenames have distinct parent directories, and `remove()` removes the task directory.

- [ ] **Step 5: Commit the isolated temporary-file unit**

```bash
git add AgoraLyricsScore/Class/Downloader/DownloadTemporaryFile.swift AgoraLyricsScore/Class/Downloader/Extentions.swift AgoraLyricsScore/Tests/TestDownload/TestDownloadTemporaryFile.swift
git commit -m "fix: isolate lyric download temporary files"
```

### Task 2: Use Fresh Files in Downloader

**Files:**
- Modify: `AgoraLyricsScore/Class/Downloader/Downloader.swift:20-153`
- Test: `AgoraLyricsScore/Tests/TestDownload/TestDownloadTemporaryFile.swift`

- [ ] **Step 1: Add a failing lifecycle assertion**

Extend the temporary-file tests to prove close preserves a successful file while remove deletes a failed file:

```swift
func testClosePreservesCompletedFileUntilConsumerCleanup() throws {
    let temporaryFile = try DownloadTemporaryFile(filename: "lyrics.zip", rootURL: rootURL)
    try temporaryFile.open()
    try temporaryFile.write(Data("complete".utf8))
    temporaryFile.close()

    XCTAssertTrue(FileManager.default.fileExists(atPath: temporaryFile.fileURL.path))
}
```

- [ ] **Step 2: Run the focused test and verify it fails before lifecycle integration is complete**

Run the same focused test command from Task 1. Expected: the new assertion passes at the helper level, while source inspection still shows `Downloader` using its own appending `OutputStream` and therefore the integration requirement remains red.

- [ ] **Step 3: Replace Downloader's shared appending stream**

Replace `localUrl` and `fileOutputStream` ownership with:

```swift
private var temporaryFile: DownloadTemporaryFile?
private var writeError: Error?
```

In `didReceive response`, construct and open the owner before allowing the response:

```swift
do {
    let file = try DownloadTemporaryFile(filename: filename)
    try file.open()
    temporaryFile = file
    completionHandler(.allow)
} catch {
    let downloadError = DownloadError(domainType: .general, error: error as NSError)
    fail?(downloadError)
    fail = nil
    completionHandler(.cancel)
    cancel()
}
```

In `didReceive data`, write all bytes and retain the first stream error:

```swift
do {
    try temporaryFile?.write(data)
} catch {
    writeError = error
    dataTask.cancel()
    return
}
```

Split session shutdown from destructive cleanup. Explicit cancellation and failed completion call `temporaryFile?.remove()` inside `do/catch` and log cleanup failures. Successful completion closes the file, captures `fileURL.path`, clears the owner's reference without deletion, shuts down the session, and invokes `completion` with that path.

- [ ] **Step 4: Verify no appending stream remains**

```bash
rg -n 'append:\s*true|fileOutputStream|localUrl' AgoraLyricsScore/Class/Downloader
```

Expected: no match in `Downloader.swift`, and focused temporary-file tests remain green.

- [ ] **Step 5: Commit Downloader integration**

```bash
git add AgoraLyricsScore/Class/Downloader/Downloader.swift AgoraLyricsScore/Tests/TestDownload/TestDownloadTemporaryFile.swift
git commit -m "fix: replace appending download output stream"
```

### Task 3: Cache Mapping and Consumer Cleanup

**Files:**
- Modify: `AgoraLyricsScore/Class/Downloader/LyricsFileDownloader.swift:105-234`
- Modify: `AgoraLyricsScore/Class/Downloader/Extentions.swift:45-64`
- Create: `AgoraLyricsScore/Tests/TestDownload/TestDownloadLifecycle.swift`

- [ ] **Step 1: Write failing cache-name and cleanup tests**

```swift
import XCTest
@testable import AgoraLyricsScore

final class TestDownloadLifecycle: XCTestCase {
    func testZipRequestMapsToExtractedXMLCacheName() {
        let downloader = LyricsFileDownloader()
        XCTAssertEqual(downloader.cachedFileName(for: "https://example.com/path/1.zip?token=abc"),
                       "1.xml")
    }

    func testLRCRequestKeepsOriginalCacheName() {
        let downloader = LyricsFileDownloader()
        XCTAssertEqual(downloader.cachedFileName(for: "https://example.com/path/8.lrc?token=abc"),
                       "8.lrc")
    }

    func testRemoveDownloadedItemHandlesTaskDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgoraLyricsScoreCleanupTests")
            .appendingPathComponent(UUID().uuidString)
        let task = try DownloadTemporaryFile(filename: "1.zip", rootURL: root)
        try task.open()
        task.close()

        FileManager.removeDownloadedItem(atPath: task.fileURL.path, downloadRoot: root)

        XCTAssertFalse(FileManager.default.fileExists(atPath: task.directoryURL.path))
        try? FileManager.default.removeItem(at: root)
    }
}
```

- [ ] **Step 2: Run tests and verify red**

Expected: compilation fails because `cachedFileName(for:)` and `removeDownloadedItem(atPath:downloadRoot:)` do not exist.

- [ ] **Step 3: Implement cache-name mapping**

Add an internal method and use it in `fetchFromLocal`:

```swift
func cachedFileName(for urlString: String) -> String {
    guard let url = URL(string: urlString) else { return urlString.fileName }
    if url.pathExtension.lowercased() == "zip" {
        return url.deletingPathExtension().lastPathComponent + ".xml"
    }
    return url.lastPathComponent
}
```

`fetchFromLocal` passes this result to `FileCache.cacheFileExists(with:)`.

- [ ] **Step 4: Implement safe transferred-file cleanup**

Add a helper that deletes the unique task directory, but only deletes the individual file for the legacy root-level layout:

```swift
static func removeDownloadedItem(atPath path: String,
                                 downloadRoot: URL = .lyricsDownloadDirectory) {
    let fileURL = URL(fileURLWithPath: path).standardizedFileURL
    let rootURL = downloadRoot.standardizedFileURL
    let parentURL = fileURL.deletingLastPathComponent()
    let targetURL = parentURL == rootURL ? fileURL : parentURL
    guard targetURL.path.hasPrefix(rootURL.path + "/") else { return }
    do {
        try FileManager.default.removeItem(at: targetURL)
    } catch {
        Log.error(error: "remove downloaded item failed: \(error.localizedDescription)",
                  tag: "Downloader Extension")
    }
}
```

Call it before returning from the LRC completion path, in a `defer` at the start of `_unzip`, and when the weak `LyricsFileDownloader` reference is already nil. Keep the primary callback result unchanged if cleanup itself fails. Update `_clearDownloadFloder()` to enumerate `URL.lyricsDownloadDirectory` directly instead of constructing a file path with `URL(string:)`.

- [ ] **Step 5: Run focused tests and verify green**

Expected: ZIP URLs map to XML without query text, LRC names remain unchanged, and only the task directory is removed.

- [ ] **Step 6: Commit cache and consumer cleanup**

```bash
git add AgoraLyricsScore/Class/Downloader/LyricsFileDownloader.swift AgoraLyricsScore/Class/Downloader/Extentions.swift AgoraLyricsScore/Tests/TestDownload/TestDownloadLifecycle.swift
git commit -m "fix: clean downloaded lyrics and resolve zip cache"
```

### Task 4: Release Failed Manager Entries

**Files:**
- Modify: `AgoraLyricsScore/Class/Downloader/DownloaderManager.swift:12-52`
- Modify: `AgoraLyricsScore/Tests/TestDownload/TestDownloadLifecycle.swift`

- [ ] **Step 1: Write a failing retry test with an injected downloader**

Add an internal downloader factory to the manager and test it with a downloader whose `download` method immediately fails:

```swift
private final class ImmediateFailureDownloader: Downloader {
    override func download(url: URL,
                           progress: @escaping DownloadProgressClosure,
                           completion: @escaping DownloadCompletionClosure,
                           fail: @escaping DownloadFailClosure) {
        fail(DownloadError(domainType: .httpDownloadError, code: -1, msg: "test"))
    }
}

func testManagerAllowsRetryAfterFailure() {
    var createdCount = 0
    let manager = DownloaderManager {
        createdCount += 1
        return ImmediateFailureDownloader()
    }
    let url = URL(string: "https://example.com/1.zip")!

    manager.download(url: url, progress: { _ in }, completion: { _ in }, fail: { _ in })
    manager.download(url: url, progress: { _ in }, completion: { _ in }, fail: { _ in })

    XCTAssertEqual(createdCount, 2)
}
```

- [ ] **Step 2: Run the focused test and verify red**

Expected: compilation fails because `DownloaderManager` does not accept a factory, or the second request reuses the failed cache entry.

- [ ] **Step 3: Add factory injection and symmetric cleanup**

Keep the public internal default initializer behavior while adding a test seam:

```swift
private let makeDownloader: () -> Downloader

override init() {
    makeDownloader = { Downloader() }
    super.init()
    Log.info(text: "init", tag: logTag)
}

init(makeDownloader: @escaping () -> Downloader) {
    self.makeDownloader = makeDownloader
    super.init()
    Log.info(text: "init", tag: logTag)
}
```

Create new instances through `makeDownloader()`. Wrap the failure closure exactly as success is wrapped:

```swift
}, fail: { [weak self] error in
    self?.downloadCache.removeValue(forkey: url.absoluteString)
    fail(error)
})
```

- [ ] **Step 4: Run the retry test and verify green**

Expected: two failed attempts construct two downloader instances and neither is rejected as a repeated in-flight request.

- [ ] **Step 5: Commit manager cleanup**

```bash
git add AgoraLyricsScore/Class/Downloader/DownloaderManager.swift AgoraLyricsScore/Tests/TestDownload/TestDownloadLifecycle.swift
git commit -m "fix: release failed lyric download tasks"
```

### Task 5: Regression Verification

**Files:**
- Verify: `AgoraLyricsScore/Class/Downloader/*.swift`
- Verify: `AgoraLyricsScore/Tests/TestDownload/*.swift`

- [ ] **Step 1: Scan for the original unsafe pattern**

```bash
rg -n 'OutputStream\(.*append:\s*true' AgoraLyricsScore
```

Expected: no matches.

- [ ] **Step 2: Run Swift syntax parsing**

```bash
xcrun swiftc -frontend -parse AgoraLyricsScore/Class/Downloader/*.swift AgoraLyricsScore/Tests/TestDownload/*.swift
```

Expected: parser exits successfully with no syntax errors.

- [ ] **Step 3: Run repository whitespace validation**

```bash
git diff --check HEAD~4..HEAD
```

Expected: no output and exit status 0.

- [ ] **Step 4: Attempt the complete project test/build command**

```bash
xcodebuild test -workspace Demo/Demo.xcworkspace -scheme AgoraLyricsScore-Unit-Tests -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath /tmp/LrcViewDerivedData
```

Expected in a configured CocoaPods checkout: all download tests pass. In the current checkout, report the missing `Pods/Pods.xcodeproj` or missing test scheme rather than claiming the suite passed.

- [ ] **Step 5: Review the final diff against the design**

Confirm that all paths use non-appending writes, every ownership transfer has cleanup, URL manager state is symmetric, public APIs are unchanged, and no unrelated files changed.

- [ ] **Step 6: Commit any final test-only adjustments**

```bash
git add AgoraLyricsScore/Tests/TestDownload
git commit -m "test: cover lyric download file lifecycle"
```
