//
//  TestMockScoring.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/2/9.
//

import XCTest
@testable import AgoraLyricsScoreEx

class TestMockScoring: XCTestCase, ScoringMachineDelegate {
    override func setUpWithError() throws {
        Log.setLoggers(loggers: [ConsoleLoggerEx()])
    }
    
    override func tearDownWithError() throws {
        vm.reset()
    }
    
    var cumulativeScore = 0
    var testCaseNum = 0
    var vm = ScoringMachine()
    let exp = XCTestExpectation(description: "test score")
    let exp2 = XCTestExpectation(description: "test score2")
    
    func testAll() { /** test score 每个tone命中一次 **/
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.krc", ofType: nil)!))
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        
        guard let model = KaraokeViewEx.parseLyricData(krcFileData: krcFileData,
                                                     pitchFileData: pitchFileData) else {
            XCTFail()
            return
        }
        vm = ScoringMachine()
        vm.delegate = self
        vm.setLyricData(data: model)
        for index in 0...5 {
            let line = model.lines[index]
            for tone in line.tones {
                let time = tone.beginTime + tone.duration/2
                vm.setProgress(progress: time)
                vm.setPitch(speakerPitch: 3,  progressInMs: time)
            }
        }
        wait(for: [exp], timeout: 3)
    }
    
    func testAll2() { /** test score 每个tone命中多次 **/
        testCaseNum = 1
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.krc", ofType: nil)!))
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        
        guard let model = KaraokeViewEx.parseLyricData(krcFileData: krcFileData,
                                                     pitchFileData: pitchFileData,
                                                     includeCopyrightSentence: false) else {
            XCTFail()
            return
        }
        
        vm = ScoringMachine()
        vm.delegate = self
        vm.setLyricData(data: model)
        
        let line = model.lines.first!
        var time = line.beginTime
        var gap = 0
        while time <= line.endTime+20 {
            vm.setProgress(progress: time)
            if gap == 40 {
                gap = 0
                vm.setPitch(speakerPitch: 3, progressInMs: time)
            }
            gap += 20
            time += 20
            Thread.sleep(forTimeInterval: 0.02)
        }
        wait(for: [exp2], timeout: 10)
    }
    
    func sizeOfCanvasView(_ scoringMachine: ScoringMachine) -> CGSize {
        return .init(width: 380, height: 100)
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachine,
                        didUpdateDraw standardInfos: [ScoringMachine.DrawInfo],
                        highlightInfos: [ScoringMachine.DrawInfo]) {
        
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachine,
                        didUpdateCursor centerY: CGFloat,
                        showAnimation: Bool,
                        debugInfo: ScoringMachine.DebugInfo) {
        if (showAnimation) {
            if testCaseNum == 1 {
                exp2.fulfill()
            }
            else {
                exp.fulfill()
            }
        }
    }
}
