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
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "6625526603631810", ofType: "bin")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parsePitchData(data: data) else {
            XCTFail()
            return
        }
        
        vm.delegate = self
        vm.setPitchData(data: model)
        for index in 0...5 {
            let item = model.items[index]
            let time = item.beginTime + item.duration/2
            vm.setProgress(progress: time)
            vm.setPitch(pitch: item.value - 1)
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
        
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachine, didFinishToneWith models: [PitchScoreModel], cumulativeScore: Int) {
        self.cumulativeScore = cumulativeScore
        print("didFinishToneWith models: \(cumulativeScore)")
        if cumulativeScore == 598 {
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

