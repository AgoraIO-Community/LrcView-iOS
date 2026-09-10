//
//  TestDownloadLifecycle.swift
//  AgoraLyricsScore-Unit-Tests
//

import Foundation
import XCTest

@testable import AgoraLyricsScore

final class TestDownloadLifecycle: XCTestCase {
    func testZipRequestMapsToExtractedXMLCacheName() {
        let url = URL(string: "https://example.com/path/1.zip?token=abc")!

        XCTAssertEqual(url.lyricsCacheFileName, "1.xml")
    }

    func testLRCRequestKeepsOriginalCacheName() {
        let url = URL(string: "https://example.com/path/8.lrc?token=abc")!

        XCTAssertEqual(url.lyricsCacheFileName, "8.lrc")
    }

    func testRemoveDownloadedItemDeletesTaskDirectory() throws {
        let rootURL = try makeRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let file = try DownloadTemporaryFile(filename: "1.zip", rootURL: rootURL)
        try file.open()
        file.close()

        FileManager.removeDownloadedItem(atPath: file.fileURL.path, downloadRoot: rootURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: file.directoryURL.path))
    }

    func testRemoveDownloadedItemPreservesLegacyDownloadRoot() throws {
        let rootURL = try makeRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let fileURL = rootURL.appendingPathComponent("legacy.zip")
        try Data("legacy".utf8).write(to: fileURL)

        FileManager.removeDownloadedItem(atPath: fileURL.path, downloadRoot: rootURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.path))
    }

    private func makeRootURL() throws -> URL {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgoraLyricsScoreLifecycleTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        return rootURL
    }
}
