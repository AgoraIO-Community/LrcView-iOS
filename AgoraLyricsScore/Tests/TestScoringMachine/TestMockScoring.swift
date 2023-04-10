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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var cumulativeScore = 0
    let vm = ScoringMachine()
    let exp = XCTestExpectation(description: "test score")
    
    func testAll() { /** test score **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "825003", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        
        vm.delegate = self
        vm.setLyricData(data: model)
        for index in 0...5 {
            let line = model.lines[index]
            for tone in line.tones {
                let time = tone.beginTime + tone.duration/2
                vm.setProgress(progress: time)
                vm.setPitch(pitch: tone.pitch - 1)
            }
        }
        wait(for: [exp], timeout: 3)
    }

    func sizeOfCanvasView(_ scoringMachine: ScoringMachine) -> CGSize {
        return .init(width: 380, height: 100)
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachine, didUpdateDraw standardInfos: [ScoringMachine.DrawInfo], highlightInfos: [ScoringMachine.DrawInfo]) {
        
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachine, didUpdateCursor centerY: CGFloat, showAnimation: Bool, debugInfo: ScoringMachine.DebugInfo) {
        
    }
   
    func scoringMachine(_ scoringMachine: ScoringMachine,
                        didFinishLineWith model: LyricLineModel,
                        score: Int,
                        cumulativeScore: Int,
                        lineIndex: Int,
                        lineCount: Int) {
        self.cumulativeScore = cumulativeScore
        print("didFinishLineWith score: \(cumulativeScore)")
        if cumulativeScore == 499 {
            exp.fulfill()
        }
    }
}

//class TestMockScoring: XCTestCase, ScoringVMDelegate {
//
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    var cumulativeScore = 0
//    func testAll() {
//        KaraokeView.setLog(printToConsole: true, writeToFile: true)
//
//        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "153378", ofType: "xml")!)
//        let data = try! Data(contentsOf: url)
//        guard let model = KaraokeView.parseLyricData(data: data) else {
//            XCTFail()
//            return
//        }
//        let vm = ScoringVM()
//        vm.delegate = self
//        vm.setLyricData(data: model)
//        vm.currentIndexOfLine = 27
//        vm.setProgress(progress: 159889)
//        vm.setProgress(progress: 159829)
//        vm.setProgress(progress: 159989)
//    }
//
//    func scoringVM(_ vm: ScoringVM, didFinishLineWith model: LyricLineModel, score: Int, cumulativeScore: Int, lineIndex: Int, lineCount: Int) {
//        self.cumulativeScore = cumulativeScore
//        print("didFinishLineWith score: \(score)")
//    }
//
//    func sizeOfCanvasView(_ vm: ScoringVM) -> CGSize {
//        return .init(width: 380, height: 100)
//    }
//
//    func scoringVM(_ vm: ScoringVM, didUpdateDraw standardInfos: [ScoringVM.DrawInfo], highlightInfos: [ScoringVM.DrawInfo]) {}
//
//    func scoringVM(_ vm: ScoringVM, didUpdateCursor centerY: CGFloat, showAnimation: Bool, debugInfo: ScoringVM.DebugInfo) {}
//
//}

class TestMockScoring2: XCTestCase, ScoringMachineDelegate {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    let vm = ScoringMachine()
    
    func testAll() { /** test score **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "660250", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        
        let fileUrl = URL(fileURLWithPath: Bundle.current.path(forResource: "qilixiang_bad1_50ms_pitch", ofType: "txt")!)
        let fileData = try! Data(contentsOf: fileUrl)
        let pitchFileString = String(data: fileData, encoding: .utf8)!
        Log.setLoggers(loggers: [ConsoleLogger()])
        vm.delegate = self
        vm.setLyricData(data: model)
        let pitchs = parse(pitchFileString: pitchFileString)
        var i = 0
        for index in 0...model.duration {
            if index % 20 == 0, index > 0 {
                vm.setProgress(progress: index)
            }
            if index % 50 == 0, index > 0 {
                if i < pitchs.count {
                    let pitch = pitchs[i]
                    vm.setPitch(pitch: pitch)
                    i += 1
                }
                else {
                    vm.setPitch(pitch: 0.0)
                }
            }
        }
        
        print("getCumulativeScore:\(vm.getCumulativeScore())")
    }
    
    private func parse(pitchFileString: String) -> [Double] {
        let array = pitchFileString.split(separator: "\n").map({ Double($0)! })
        return array
    }

    func sizeOfCanvasView(_ scoringMachine: ScoringMachine) -> CGSize {
        return .init(width: 380, height: 100)
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachine, didUpdateDraw standardInfos: [ScoringMachine.DrawInfo], highlightInfos: [ScoringMachine.DrawInfo]) {
        
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachine, didUpdateCursor centerY: CGFloat, showAnimation: Bool, debugInfo: ScoringMachine.DebugInfo) {
        
    }
   
    func scoringMachine(_ scoringMachine: ScoringMachine,
                        didFinishLineWith model: LyricLineModel,
                        score: Int,
                        cumulativeScore: Int,
                        lineIndex: Int,
                        lineCount: Int) {
        print("didFinishLineWith score[\(lineIndex)]: \(score) \(model.content)")
    }
}
