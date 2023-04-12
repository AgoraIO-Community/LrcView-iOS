//
//  TestEstimateScore.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/4/10.
//

import XCTest
@testable import AgoraLyricsScore

class TestEstimateScore: XCTestCase, ScoringMachineDelegate {
    var vm: ScoringMachine!
    var fileName = ""
    
    func testBad1() {
        fileName = "qilixiang_bad1_50ms_pitch"
        goTest(fileName: fileName)
    }
    
    func testGood1() {
        fileName = "qilixiang_good1_50ms_pitch"
        goTest(fileName: fileName)
    }
    
    func testGood2() {
        fileName = "qilixiang_good2_50ms_pitch"
        goTest(fileName: fileName)
    }
    
    func testGood3() {
        fileName = "qilixiang_good3_50ms_pitch"
        goTest(fileName: fileName)
    }
    
    func testGood4() {
        fileName = "qilixiang_good4_50ms_pitch"
        goTest(fileName: fileName)
    }
    
    func goTest(fileName: String) {
        vm = ScoringMachine()
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "660250", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        
        let fileUrl = URL(fileURLWithPath: Bundle.current.path(forResource: fileName, ofType: "txt")!)
        let fileData = try! Data(contentsOf: fileUrl)
        let pitchFileString = String(data: fileData, encoding: .utf8)!
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
            }
            usleep(5)
        }
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
        if lineIndex == 0 {
            print("---------\(fileName)  start ----------")
        }
        print("didFinishLineWith score[\(lineIndex)]: \(score) \(model.content)")
        if lineIndex == 48 {
            print("cumulativeScore:\(cumulativeScore)")
            print("---------\(fileName)  end ----------\n")
        }
    }
}
