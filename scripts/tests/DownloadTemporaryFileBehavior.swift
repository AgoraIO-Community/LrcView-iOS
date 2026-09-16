import Foundation

enum Log {
    static func debug(text: String, tag: String = "") {}
    static func errorText(text: String, tag: String = "") {}
    static func info(text: String, tag: String = "") {}
    static func error(error: String, tag: String = "") {}
}

enum BehaviorTestError: Error, CustomStringConvertible {
    case assertionFailed(String)

    var description: String {
        switch self {
        case .assertionFailed(let message):
            return message
        }
    }
}

@main
struct DownloadTemporaryFileBehaviorTest {
    static func main() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgoraLyricsScoreBehaviorTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        try testFreshWrite(rootURL: rootURL)
        try testFilenameIsolation(rootURL: rootURL)
        try testCloseAndRemove(rootURL: rootURL)
        try testDownloadDirectoryUsesSystemTemporaryDirectory()
        try testFilenameCannotEscapeTaskDirectory(rootURL: rootURL)
        try testCacheFilenameMapping()
        try testDownloadedItemCleanup(rootURL: rootURL)
        try testOnlyRegularFileIgnoresNameAndExtension(rootURL: rootURL)
        try testOnlyRegularFileSupportsHiddenFilename(rootURL: rootURL)
        try testOnlyRegularFileSupportsNestedContent(rootURL: rootURL)
        try testOnlyRegularFileRejectsInvalidCounts(rootURL: rootURL)
        try testArchiveFailureDescriptionIncludesContext()
        try testDownloadedLyricsFileReadsAndCachesData(rootURL: rootURL)
        try testDownloadedLyricsFileThrowsWhenSourceCannotBeRead(rootURL: rootURL)
        try testDownloadedLyricsFileReturnsCacheFailure(rootURL: rootURL)
        print("DownloadTemporaryFile behavior tests passed")
    }

    private static func testFreshWrite(rootURL: URL) throws {
        let file = try DownloadTemporaryFile(filename: "lyrics.zip",
                                             rootURL: rootURL,
                                             identifier: "fresh-write")
        try Data("old".utf8).write(to: file.fileURL)
        try file.open()
        try file.write(Data("new".utf8))
        file.close()

        let writtenData = try Data(contentsOf: file.fileURL)
        try require(writtenData == Data("new".utf8),
                    "opening a download file must truncate old content")
    }

    private static func testFilenameIsolation(rootURL: URL) throws {
        let first = try DownloadTemporaryFile(filename: "lyrics.zip", rootURL: rootURL)
        let second = try DownloadTemporaryFile(filename: "lyrics.zip", rootURL: rootURL)

        try require(first.fileURL != second.fileURL,
                    "same response filenames must use distinct task paths")
    }

    private static func testCloseAndRemove(rootURL: URL) throws {
        let file = try DownloadTemporaryFile(filename: "lyrics.zip", rootURL: rootURL)
        try file.open()
        try file.write(Data("complete".utf8))
        file.close()

        try require(FileManager.default.fileExists(atPath: file.fileURL.path),
                    "close must preserve a completed file for its consumer")
        try file.remove()
        try require(!FileManager.default.fileExists(atPath: file.directoryURL.path),
                    "remove must delete the complete task directory")
    }

    private static func testDownloadDirectoryUsesSystemTemporaryDirectory() throws {
        try require(String.downloadedFloderPath() == DownloadTemporaryFile.defaultRootURL.path,
                    "download root must use FileManager.default.temporaryDirectory")
    }

    private static func testFilenameCannotEscapeTaskDirectory(rootURL: URL) throws {
        let file = try DownloadTemporaryFile(filename: "../lyrics.zip", rootURL: rootURL)

        try require(file.fileURL.deletingLastPathComponent() == file.directoryURL,
                    "response filename must not escape its task directory")
        try require(file.fileURL.lastPathComponent == "lyrics.zip",
                    "response filename must keep only its last path component")
    }

    private static func testCacheFilenameMapping() throws {
        let zipURL = URL(string: "https://example.com/path/1.zip?token=abc")!
        let lrcURL = URL(string: "https://example.com/path/8.lrc?token=abc")!

        try require(zipURL.lyricsCacheFileName == "1.xml",
                    "ZIP requests must resolve to the extracted XML cache filename")
        try require(lrcURL.lyricsCacheFileName == "8.lrc",
                    "non-ZIP requests must preserve their response filename")
    }

    private static func testDownloadedItemCleanup(rootURL: URL) throws {
        let taskFile = try DownloadTemporaryFile(filename: "1.zip", rootURL: rootURL)
        try taskFile.open()
        taskFile.close()
        FileManager.removeDownloadedItem(atPath: taskFile.fileURL.path,
                                         downloadRoot: rootURL)
        try require(!FileManager.default.fileExists(atPath: taskFile.directoryURL.path),
                    "consumer cleanup must remove a task directory")

        let legacyFileURL = rootURL.appendingPathComponent("legacy.zip")
        try Data("legacy".utf8).write(to: legacyFileURL)
        FileManager.removeDownloadedItem(atPath: legacyFileURL.path,
                                         downloadRoot: rootURL)
        try require(!FileManager.default.fileExists(atPath: legacyFileURL.path),
                    "consumer cleanup must remove a legacy root-level file")
        try require(FileManager.default.fileExists(atPath: rootURL.path),
                    "consumer cleanup must preserve the download root")
    }

    private static func testOnlyRegularFileIgnoresNameAndExtension(rootURL: URL) throws {
        let extractionURL = rootURL.appendingPathComponent("arbitrary-name", isDirectory: true)
        try FileManager.default.createDirectory(at: extractionURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        let lyricURL = extractionURL.appendingPathComponent("payload-without-extension")
        try Data("lyrics".utf8).write(to: lyricURL)

        let selectedURL = try LyricsArchiveContent.onlyRegularFile(in: extractionURL)

        try require(selectedURL.resolvingSymlinksInPath() == lyricURL.resolvingSymlinksInPath(),
                    "archive selection must ignore the extracted filename and extension")
    }

    private static func testOnlyRegularFileSupportsNestedContent(rootURL: URL) throws {
        let extractionURL = rootURL.appendingPathComponent("nested-content", isDirectory: true)
        let nestedURL = extractionURL.appendingPathComponent("folder", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        let lyricURL = nestedURL.appendingPathComponent("lyrics.data")
        try Data("lyrics".utf8).write(to: lyricURL)

        let selectedURL = try LyricsArchiveContent.onlyRegularFile(in: extractionURL)

        try require(selectedURL.resolvingSymlinksInPath() == lyricURL.resolvingSymlinksInPath(),
                    "archive selection must find a sole file below nested directories")
    }

    private static func testOnlyRegularFileSupportsHiddenFilename(rootURL: URL) throws {
        let extractionURL = rootURL.appendingPathComponent("hidden-name", isDirectory: true)
        try FileManager.default.createDirectory(at: extractionURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        let lyricURL = extractionURL.appendingPathComponent(".lyrics")
        try Data("lyrics".utf8).write(to: lyricURL)

        let selectedURL = try LyricsArchiveContent.onlyRegularFile(in: extractionURL)

        try require(selectedURL.resolvingSymlinksInPath() == lyricURL.resolvingSymlinksInPath(),
                    "archive selection must not exclude a file based on its name")
    }

    private static func testOnlyRegularFileRejectsInvalidCounts(rootURL: URL) throws {
        let emptyURL = rootURL.appendingPathComponent("empty", isDirectory: true)
        try FileManager.default.createDirectory(at: emptyURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        try requireThrows({ try LyricsArchiveContent.onlyRegularFile(in: emptyURL) },
                          "an archive with no regular file must fail")

        let multipleURL = rootURL.appendingPathComponent("multiple", isDirectory: true)
        try FileManager.default.createDirectory(at: multipleURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        try Data("first".utf8).write(to: multipleURL.appendingPathComponent("first.xml"))
        try Data("second".utf8).write(to: multipleURL.appendingPathComponent("second.lrc"))
        try requireThrows({ try LyricsArchiveContent.onlyRegularFile(in: multipleURL) },
                          "an archive with multiple regular files must fail")
    }

    private static func testArchiveFailureDescriptionIncludesContext() throws {
        let error = NSError(domain: "test",
                            code: 9,
                            userInfo: [NSLocalizedDescriptionKey: "broken archive"])
        let description = LyricsArchiveProcessingStep.unzipArchive.failureDescription(
            requestId: 7,
            archivePath: "/tmp/song.zip",
            error: error
        )

        try require(description.contains("requestId:7"),
                    "archive failure log must include the request ID")
        try require(description.contains("step:unzip archive"),
                    "archive failure log must include the failed step")
        try require(description.contains("archive:/tmp/song.zip"),
                    "archive failure log must include the ZIP path")
        try require(description.contains("error:broken archive"),
                    "archive failure log must include the underlying error")
    }

    private static func testDownloadedLyricsFileReadsAndCachesData(rootURL: URL) throws {
        let sourceURL = rootURL.appendingPathComponent("downloaded.lrc")
        let cacheURL = rootURL.appendingPathComponent("cache/lyrics.lrc")
        let expectedData = Data("[00:01.00]lyrics".utf8)
        try expectedData.write(to: sourceURL)

        let result = try DownloadedLyricsFile.consume(sourceURL: sourceURL,
                                                      cacheURL: cacheURL)

        try require(result.data == expectedData,
                    "downloaded lyrics consumption must return source data")
        try require(result.cacheError == nil,
                    "downloaded lyrics consumption must not report a successful cache write as failed")
        let cachedData = try Data(contentsOf: cacheURL)
        try require(cachedData == expectedData,
                    "downloaded lyrics consumption must cache source data")
    }

    private static func testDownloadedLyricsFileThrowsWhenSourceCannotBeRead(rootURL: URL) throws {
        let missingURL = rootURL.appendingPathComponent("missing.lrc")
        let cacheURL = rootURL.appendingPathComponent("missing-cache/lyrics.lrc")

        try requireThrows({ try DownloadedLyricsFile.consume(sourceURL: missingURL,
                                                             cacheURL: cacheURL) },
                          "an unreadable downloaded lyrics file must fail")
    }

    private static func testDownloadedLyricsFileReturnsCacheFailure(rootURL: URL) throws {
        let sourceURL = rootURL.appendingPathComponent("cache-failure.lrc")
        let cacheURL = rootURL.appendingPathComponent("cache-target", isDirectory: true)
        let expectedData = Data("[00:01.00]lyrics".utf8)
        try expectedData.write(to: sourceURL)
        try FileManager.default.createDirectory(at: cacheURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)

        let result = try DownloadedLyricsFile.consume(sourceURL: sourceURL,
                                                      cacheURL: cacheURL)

        try require(result.data == expectedData,
                    "a cache failure must not discard downloaded lyrics data")
        try require(result.cacheError != nil,
                    "a failed cache write must be returned for logging")
    }

    private static func requireThrows<T>(_ operation: () throws -> T,
                                         _ message: String) throws {
        var didThrow = false
        do {
            _ = try operation()
        } catch {
            didThrow = true
        }
        try require(didThrow, message)
    }

    private static func require(_ condition: @autoclosure () -> Bool,
                                _ message: String) throws {
        guard condition() else {
            throw BehaviorTestError.assertionFailed(message)
        }
    }
}
