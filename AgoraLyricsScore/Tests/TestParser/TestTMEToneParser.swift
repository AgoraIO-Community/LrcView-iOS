import XCTest
@testable import AgoraLyricsScore

final class TestTMEToneParser: XCTestCase {
    func testConvertsPitchAndPreservesUnscoredLyrics() throws {
        let model = try parse(
            pitches: """
            [{"st":"1200","d":"100","p":"54"},
             {"st":"2300","d":"300","p":"32"},
             {"st":3400,"d":200,"p":44},
             {"st":3500,"d":100,"p":20}]
            """,
            lyrics: "[ti:要强]\n[ar:房祖名]\n[00:00.00]要强 - 房祖名\n[00:01.20]词：某人\n[00:02.30]唱一句\n[00:03.40]下一句\n[00:04.00]"
        )

        XCTAssertEqual(model.name, "要强")
        XCTAssertEqual(model.singer, "房祖名")
        XCTAssertEqual(model.lyricsType, .lrc)
        XCTAssertEqual(model.lines.count, 5)
        XCTAssertEqual(model.lines[2].beginTime, 2300)
        XCTAssertEqual(model.lines[2].content, "唱一句")
        XCTAssertTrue(model.lines[0].tones.isEmpty)
        XCTAssertTrue(model.lines[1].tones.isEmpty)
        XCTAssertTrue(model.lines[4].tones.isEmpty)
        XCTAssertEqual(model.lines[2].tones[0].pitch, 55 * (1 - 1e-6), accuracy: 1e-6)
        XCTAssertEqual(model.lines[3].tones[0].pitch, 55 * (2 - 1e-6), accuracy: 1e-6)
        XCTAssertEqual(model.scoringLines?.map(\.content), ["唱一句", "下一句"])
        XCTAssertEqual(model.preludeEndPosition, 2300)
        XCTAssertTrue(model.hasPitch)
    }

    func testCentisecondBoundaryAndCrossingNote() throws {
        let model = try parse(
            pitches: """
            [{"st":"43000","d":"500","p":"54"},
             {"st":"43300","d":"200","p":"56"},
             {"st":"43502","d":"400","p":"57"}]
            """,
            lyrics: "[00:43.00]第一句\n[00:43.30]第二句\n[00:43.502]第三句"
        )

        XCTAssertEqual(model.lines.map(\.beginTime), [43000, 43300, 43502])
        XCTAssertEqual(model.lines[0].tones.map(\.duration), [300])
        XCTAssertEqual(model.lines[1].tones.map(\.duration), [200])
        XCTAssertEqual(model.lines[2].tones.map(\.duration), [400])
        XCTAssertEqual(model.lines[2].duration, 400)
        XCTAssertEqual(model.scoringLines?.count, 3)
    }

    func testSkipsInvalidRecordsAndTimedCredits() throws {
        let model = try parse(
            pitches: """
            [{"st":"1000","d":"200","p":"54"},
             {"st":"2000","d":"100","p":"54"},
             {"st":"3000","d":"300","p":"52"},
             {"st":"3400","d":"100","p":"31"},
             {"st":"bad","d":"100","p":"54"},
             {"st":"3500","d":"0","p":"54"},
             {"st":"3600","d":"100","p":true},
             {"st":"4000","d":"100","p":"1e309"}]
            """,
            lyrics: "[ti:歌名]\n[ar:歌手]\n[00:00.00]歌名 - 歌手\n[00:01.00]作曲：某人\n[00:02.00]\n[00:03.00]唱一句\n[00:04.00]"
        )

        XCTAssertEqual(model.lines.count, 5)
        XCTAssertEqual(model.lines[1].tones.count, 0)
        XCTAssertEqual(model.lines[2].tones.count, 0)
        XCTAssertEqual(model.lines[3].tones.count, 1)
        XCTAssertEqual(model.scoringLines?.map(\.content), ["唱一句"])
    }

    func testReturnsNilWhenNoScorableNotesRemain() throws {
        let lyrics = "[00:01.00]词：某人\n[00:02.00]唱一句"
        XCTAssertNil(try parseOptional(pitches: "[]", lyrics: lyrics))
        XCTAssertNil(try parseOptional(pitches: "[{}]", lyrics: lyrics))
        XCTAssertNil(try parseOptional(pitches: "{\"st\":\"2000\"}", lyrics: lyrics))
        XCTAssertNil(try parseOptional(pitches: "[{\"st\":\"1000\",\"d\":\"200\",\"p\":\"54\"}]", lyrics: lyrics))
        XCTAssertNil(try parseOptional(pitches: "[]", lyrics: "[ti:只有标题]"))
    }

    func testReturnsNilForMissingPaths() {
        XCTAssertNil(KaraokeView.parseTMEToneData("/nonexistent/song_pitch.txt",
                                                    "/nonexistent/song_lyric.txt"))
    }

    func testLastLineEndsAfterLongestOverlappingNote() throws {
        let model = try parse(pitches: """
                              [{"st":"2500","d":"100","p":"54"},
                               {"st":"2000","d":"1000","p":"54"}]
                              """,
                              lyrics: "[00:02.00]最后一句")

        XCTAssertEqual(model.lines[0].tones.map(\.beginTime), [2000, 2500])
        XCTAssertEqual(model.lines[0].duration, 1000)
        XCTAssertEqual(model.duration, 3000)
    }

    private func parse(pitches: String, lyrics: String) throws -> LyricModel {
        try XCTUnwrap(parseOptional(pitches: pitches, lyrics: lyrics))
    }

    private func parseOptional(pitches: String, lyrics: String) throws -> LyricModel? {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let pitchPath = folder.appendingPathComponent("song_pitch.txt")
        let lyricPath = folder.appendingPathComponent("song_lyric.txt")
        try Data(pitches.utf8).write(to: pitchPath)
        try Data(lyrics.utf8).write(to: lyricPath)
        return KaraokeView.parseTMEToneData(pitchPath.path, lyricPath.path)
    }
}
