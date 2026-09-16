//
//  TestLyricsArchiveContent.swift
//  AgoraLyricsScore-Unit-Tests
//

import Foundation
import XCTest

@testable import AgoraLyricsScore

final class TestLyricsArchiveContent: XCTestCase {
    private var rootURL: URL!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AgoraLyricsScoreArchiveTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: rootURL)
    }

    func testReturnsOnlyRegularFileWithoutInspectingNameOrExtension() throws {
        let lyricURL = rootURL.appendingPathComponent("arbitrary-payload")
        try Data("lyrics".utf8).write(to: lyricURL)

        let selectedURL = try LyricsArchiveContent.onlyRegularFile(in: rootURL)
        XCTAssertEqual(selectedURL.resolvingSymlinksInPath(), lyricURL.resolvingSymlinksInPath())
    }

    func testReturnsOnlyRegularFileFromNestedDirectory() throws {
        let nestedURL = rootURL.appendingPathComponent("folder", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        let lyricURL = nestedURL.appendingPathComponent("lyrics.anything")
        try Data("lyrics".utf8).write(to: lyricURL)

        let selectedURL = try LyricsArchiveContent.onlyRegularFile(in: rootURL)
        XCTAssertEqual(selectedURL.resolvingSymlinksInPath(), lyricURL.resolvingSymlinksInPath())
    }

    func testReturnsOnlyRegularFileWithHiddenFilename() throws {
        let lyricURL = rootURL.appendingPathComponent(".lyrics")
        try Data("lyrics".utf8).write(to: lyricURL)

        let selectedURL = try LyricsArchiveContent.onlyRegularFile(in: rootURL)
        XCTAssertEqual(selectedURL.resolvingSymlinksInPath(), lyricURL.resolvingSymlinksInPath())
    }

    func testThrowsWhenNoRegularFileExists() {
        XCTAssertThrowsError(try LyricsArchiveContent.onlyRegularFile(in: rootURL))
    }

    func testThrowsWhenMultipleRegularFilesExist() throws {
        try Data("first".utf8).write(to: rootURL.appendingPathComponent("first.xml"))
        try Data("second".utf8).write(to: rootURL.appendingPathComponent("second.lrc"))

        XCTAssertThrowsError(try LyricsArchiveContent.onlyRegularFile(in: rootURL))
    }

    func testFailureDescriptionIncludesRequestStepPathAndError() {
        let error = NSError(domain: "test",
                            code: 9,
                            userInfo: [NSLocalizedDescriptionKey: "broken archive"])

        let description = LyricsArchiveProcessingStep.unzipArchive.failureDescription(
            requestId: 7,
            archivePath: "/tmp/song.zip",
            error: error
        )

        XCTAssertTrue(description.contains("requestId:7"))
        XCTAssertTrue(description.contains("step:unzip archive"))
        XCTAssertTrue(description.contains("archive:/tmp/song.zip"))
        XCTAssertTrue(description.contains("error:broken archive"))
    }
}
