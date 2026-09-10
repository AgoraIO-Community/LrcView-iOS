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

    private static func require(_ condition: @autoclosure () -> Bool,
                                _ message: String) throws {
        guard condition() else {
            throw BehaviorTestError.assertionFailed(message)
        }
    }
}
