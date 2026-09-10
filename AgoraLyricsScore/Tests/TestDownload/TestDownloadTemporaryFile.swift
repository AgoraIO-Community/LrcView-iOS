//
//  TestDownloadTemporaryFile.swift
//  AgoraLyricsScore-Unit-Tests
//

import Foundation
import XCTest

#if canImport(AgoraLyricsScore)
@testable import AgoraLyricsScore
#endif

final class TestDownloadTemporaryFile: XCTestCase {
    private var rootURL: URL!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgoraLyricsScoreTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
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

    func testClosePreservesCompletedFileUntilConsumerCleanup() throws {
        let temporaryFile = try DownloadTemporaryFile(filename: "lyrics.zip", rootURL: rootURL)
        try temporaryFile.open()
        try temporaryFile.write(Data("complete".utf8))

        temporaryFile.close()

        XCTAssertTrue(FileManager.default.fileExists(atPath: temporaryFile.fileURL.path))
    }

    func testDownloadDirectoryUsesSystemTemporaryDirectory() {
        XCTAssertEqual(String.downloadedFloderPath(), DownloadTemporaryFile.defaultRootURL.path)
    }

    func testFilenameCannotEscapeTaskDirectory() throws {
        let temporaryFile = try DownloadTemporaryFile(filename: "../lyrics.zip", rootURL: rootURL)

        XCTAssertEqual(temporaryFile.fileURL.deletingLastPathComponent(), temporaryFile.directoryURL)
        XCTAssertEqual(temporaryFile.fileURL.lastPathComponent, "lyrics.zip")
    }
}

#if STANDALONE_TEST
extension TestDownloadTemporaryFile {
    static var allTests = [
        ("testOpenStartsWithEmptyFile", testOpenStartsWithEmptyFile),
        ("testSameFilenameUsesDifferentTaskDirectories", testSameFilenameUsesDifferentTaskDirectories),
        ("testRemoveDeletesWholeTaskDirectory", testRemoveDeletesWholeTaskDirectory),
        ("testClosePreservesCompletedFileUntilConsumerCleanup", testClosePreservesCompletedFileUntilConsumerCleanup),
        ("testDownloadDirectoryUsesSystemTemporaryDirectory", testDownloadDirectoryUsesSystemTemporaryDirectory),
        ("testFilenameCannotEscapeTaskDirectory", testFilenameCannotEscapeTaskDirectory)
    ]
}

@main
private struct TestRunner {
    static func main() {
        XCTMain([
            testCase(TestDownloadTemporaryFile.allTests)
        ])
    }
}
#endif
