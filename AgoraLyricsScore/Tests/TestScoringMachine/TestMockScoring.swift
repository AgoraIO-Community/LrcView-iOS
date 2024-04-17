//
//  TestMockScoring.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/2/9.
//

import XCTest
@testable import AgoraLyricsScore

class TestMockScoring: XCTestCase, ScoringMachineDelegate {
    override func setUpWithError() throws {
        Log.setLoggers(loggers: [ConsoleLogger()])
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
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "825003", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        vm = ScoringMachine()
        vm.scoreLevel = 10
        vm.delegate = self
        vm.setLyricData(data: model)
        for index in 0...5 {
            let line = model.lines[index]
            for tone in line.tones {
                let time = tone.beginTime + tone.duration/2
                vm.setProgress(progress: time)
                vm.setPitch(speakerPitch: tone.pitch - 1, pitchScore: 90, progressInMs: time)
            }
        }
        wait(for: [exp], timeout: 3)
    }
    
    func testAll2() { /** test score 每个tone命中多次 **/
        testCaseNum = 1
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "825003", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        
        vm = ScoringMachine()
        vm.delegate = self
        vm.scoreLevel = 15
        vm.setLyricData(data: model)
        
        let line = model.lines.first!
        var time = line.beginTime
        var gap = 0
        while time <= line.endTime+20 {
            vm.setProgress(progress: time)
            if gap == 40 {
                gap = 0
                vm.setPitch(speakerPitch: 50, pitchScore: 90, progressInMs: time)
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
