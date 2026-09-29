import XCTest
@testable import AgoraLyricsScore

final class TestTMEToneScoring: XCTestCase {
    func testOnlyScorableLyricsProduceLineCallbacks() throws {
        let lyrics = "[ti:歌名]\n[00:00.00]歌名\n[00:01.00]词：某人\n[00:02.00]唱句一\n[00:03.00]\n[00:04.00]唱句二\n[00:05.00]"
        let pitches = """
        [{"st":"1000","d":"100","p":"44"},
         {"st":"2100","d":"100","p":"44"},
         {"st":"4100","d":"100","p":"54"}]
        """
        let model = try XCTUnwrap(TMEToneParser().parse(tone: Data(pitches.utf8),
                                                        lyric: Data(lyrics.utf8)))
        XCTAssertEqual(model.lines.count, 6)
        XCTAssertEqual(model.scoringLines?.count, 2)

        let machine = ScoringMachine()
        let finished = expectation(description: "two scorable lines")
        finished.expectedFulfillmentCount = 2
        let recorder = Recorder(expectation: finished)
        machine.delegate = recorder
        machine.setLyricData(data: model)
        machine.setProgress(progress: 2100)
        machine.setPitch(speakerPitch: model.lines[2].tones[0].pitch, progressInMs: 2100)
        machine.setProgress(progress: 2201)
        machine.setProgress(progress: 4100)
        machine.setPitch(speakerPitch: model.lines[4].tones[0].pitch, progressInMs: 4100)
        machine.setProgress(progress: 4201)

        wait(for: [finished], timeout: 4)
        XCTAssertEqual(recorder.contents, ["唱句一", "唱句二"])
        XCTAssertEqual(recorder.lineIndices, [0, 1])
        XCTAssertEqual(recorder.lineCounts, [2, 2])
        XCTAssertEqual(recorder.scores.count, 2)
        XCTAssertEqual(recorder.cumulativeScores.last,
                       recorder.scores.reduce(0, +))
        XCTAssertTrue(recorder.allOnMainThread)
    }

    func testTMENoteEndIsExclusiveButLegacyEndRemainsInclusive() throws {
        let lyrics = "[00:01.00]唱句\n[00:02.00]"
        let pitches = "[{\"st\":\"1000\",\"d\":\"200\",\"p\":\"44\"}]"
        let model = try XCTUnwrap(TMEToneParser().parse(tone: Data(pitches.utf8),
                                                        lyric: Data(lyrics.utf8)))
        let finished = expectation(description: "line ended without end-boundary sample")
        let recorder = Recorder(expectation: finished)
        let machine = ScoringMachine()
        machine.delegate = recorder
        machine.setLyricData(data: model)
        machine.setProgress(progress: 1200)
        machine.setPitch(speakerPitch: model.lines[0].tones[0].pitch, progressInMs: 1200)
        machine.setProgress(progress: 1201)

        wait(for: [finished], timeout: 4)
        XCTAssertEqual(recorder.scores, [0])

        let (_, legacyInfos) = ScoringMachine.createData(data: LyricModel(name: "旧歌",
                                                                          singer: "",
                                                                          lyricsType: .xml,
                                                                          lines: [model.lines[0]],
                                                                          preludeEndPosition: 1000,
                                                                          duration: 1200,
                                                                          hasPitch: true))
        XCTAssertNotNil(machine.getHitedInfo(progress: 1200,
                                              currentVisiableInfos: legacyInfos))
    }

    func testOverlappingTMENotesKeepTheLatestLineEnd() throws {
        let lyrics = "[00:02.00]唱句"
        let pitches = """
        [{"st":"2000","d":"1000","p":"54"},
         {"st":"2500","d":"100","p":"56"}]
        """
        let model = try XCTUnwrap(TMEToneParser().parse(tone: Data(pitches.utf8),
                                                        lyric: Data(lyrics.utf8)))
        let (lineEnds, _) = ScoringMachine.createData(data: model)

        XCTAssertEqual(lineEnds, [3000])
    }

    private final class Recorder: NSObject, ScoringMachineDelegate {
        let expectation: XCTestExpectation
        var contents = [String]()
        var lineIndices = [Int]()
        var lineCounts = [Int]()
        var scores = [Int]()
        var cumulativeScores = [Int]()
        var allOnMainThread = true

        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }

        func sizeOfCanvasView(_ scoringMachine: ScoringMachineProtocol) -> CGSize {
            CGSize(width: 300, height: 120)
        }

        func scoringMachine(_ scoringMachine: ScoringMachineProtocol,
                            didUpdateDraw standardInfos: [ScoringMachineDrawInfo],
                            highlightInfos: [ScoringMachineDrawInfo]) {}

        func scoringMachine(_ scoringMachine: ScoringMachineProtocol,
                            didUpdateCursor centerY: CGFloat,
                            showAnimation: Bool,
                            debugInfo: ScoringMachineDebugInfo) {}

        func scoringMachine(_ scoringMachine: ScoringMachineProtocol,
                            didFinishLineWith model: LyricLineModel,
                            score: Int,
                            cumulativeScore: Int,
                            lineIndex: Int,
                            lineCount: Int) {
            allOnMainThread = allOnMainThread && Thread.isMainThread
            contents.append(model.content)
            lineIndices.append(lineIndex)
            lineCounts.append(lineCount)
            scores.append(score)
            cumulativeScores.append(cumulativeScore)
            expectation.fulfill()
        }
    }
}
