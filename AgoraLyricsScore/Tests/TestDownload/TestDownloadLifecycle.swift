//
//  TestDownloadLifecycle.swift
//  AgoraLyricsScore-Unit-Tests
//

import Foundation
import XCTest

@testable import AgoraLyricsScore

final class TestDownloadLifecycle: XCTestCase {
    private final class ImmediateFailureDownloader: Downloader {
        override func download(url: URL,
                               progress: @escaping DownloadProgressClosure,
                               completion: @escaping DownloadCompletionClosure,
                               fail: @escaping DownloadFailClosure) {
            fail(DownloadError(domainType: .httpDownloadError,
                               code: -1,
                               msg: "test"))
        }
    }

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

    func testManagerAllowsRetryAfterFailure() {
        var createdCount = 0
        let manager = DownloaderManager(makeDownloader: {
            createdCount += 1
            return ImmediateFailureDownloader()
        })
        let url = URL(string: "https://example.com/1.zip")!

        manager.download(url: url, progress: { _ in }, completion: { _ in }, fail: { _ in })
        manager.download(url: url, progress: { _ in }, completion: { _ in }, fail: { _ in })

        XCTAssertEqual(createdCount, 2)
    }

    func testDownloadedLyricsFileReadsAndCachesData() throws {
        let rootURL = try makeRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let sourceURL = rootURL.appendingPathComponent("downloaded.lrc")
        let cacheURL = rootURL.appendingPathComponent("cache/lyrics.lrc")
        let expectedData = Data("[00:01.00]lyrics".utf8)
        try expectedData.write(to: sourceURL)

        let result = try DownloadedLyricsFile.consume(sourceURL: sourceURL,
                                                      cacheURL: cacheURL)

        XCTAssertEqual(result.data, expectedData)
        XCTAssertNil(result.cacheError)
        XCTAssertEqual(try Data(contentsOf: cacheURL), expectedData)
    }

    func testDownloadedLyricsFileThrowsWhenSourceCannotBeRead() throws {
        let rootURL = try makeRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }

        XCTAssertThrowsError(try DownloadedLyricsFile.consume(
            sourceURL: rootURL.appendingPathComponent("missing.lrc"),
            cacheURL: rootURL.appendingPathComponent("cache/lyrics.lrc")
        ))
    }

    func testDownloadedLyricsFileReturnsCacheFailureWithoutDiscardingData() throws {
        let rootURL = try makeRootURL()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let sourceURL = rootURL.appendingPathComponent("downloaded.lrc")
        let cacheURL = rootURL.appendingPathComponent("cache-target", isDirectory: true)
        let expectedData = Data("[00:01.00]lyrics".utf8)
        try expectedData.write(to: sourceURL)
        try FileManager.default.createDirectory(at: cacheURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)

        let result = try DownloadedLyricsFile.consume(sourceURL: sourceURL,
                                                      cacheURL: cacheURL)

        XCTAssertEqual(result.data, expectedData)
        XCTAssertNotNil(result.cacheError)
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
