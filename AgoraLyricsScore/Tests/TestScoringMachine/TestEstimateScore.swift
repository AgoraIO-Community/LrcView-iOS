//
//  TestEstimateScore.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/4/10.
//

import XCTest
@testable import AgoraLyricsScore

/// 测试分数估计
class TestEstimateScore: XCTestCase, ScoringMachineDelegate {
    var vm: ScoringMachine!
    var fileName = ""
    let expBad1_A = XCTestExpectation(description: "Bad1_A")
    let expGood1_A = XCTestExpectation(description: "Good1_A")
    let expGood2_A = XCTestExpectation(description: "Good2_A")
    let expGood3_A = XCTestExpectation(description: "Good3_A")
    let expGood4_A = XCTestExpectation(description: "Good4_A")
    let exp_Bad1_B = XCTestExpectation(description: "exp_Bad1_B")
    let exp_Good1_B = XCTestExpectation(description: "Good1_B")
    let exp_Good2_B = XCTestExpectation(description: "exp_Good1_B")
    
    override func setUpWithError() throws {
//        Log.setLoggers(loggers: [ConsoleLogger()])
    }
    
    func testBad1_A() { /** cumulativeScore:1943 **/
        fileName = "qilixiang_bad1_50ms_pitch"
        goTest(fileName: fileName, xmlFileName: "660250")
        wait(for: [expBad1_A], timeout: 3)
    }
    
    func testGood1_A() { /// cumulativeScore:1726
        fileName = "qilixiang_good1_50ms_pitch"
        goTest(fileName: fileName, xmlFileName: "660250")
        wait(for: [expGood1_A], timeout: 3)
    }
    
    func testGood2_A() { /// cumulativeScore:626
        fileName = "qilixiang_good2_50ms_pitch"
        goTest(fileName: fileName, xmlFileName: "660250")
        wait(for: [expGood2_A], timeout: 3)
    }
    
    func testGood3_A() { /// cumulativeScore:2283
        fileName = "qilixiang_good3_50ms_pitch"
        goTest(fileName: fileName, xmlFileName: "660250")
        wait(for: [expGood3_A], timeout: 3)
    }
    
    func testGood4_A() { /// cumulativeScore:2110
        fileName = "qilixiang_good4_50ms_pitch"
        goTest(fileName: fileName, xmlFileName: "660250")
        wait(for: [expGood4_A], timeout: 3)
    }
    
    func testBad1_B() { /// cumulativeScore:2953
        fileName = "houlai_bad1_50ms_pitch"
        goTest(fileName: fileName, xmlFileName: "900318")
        wait(for: [exp_Bad1_B], timeout: 3)
    }
    
    func testGood1_B() { /// cumulativeScore:4454
        fileName = "houlai_good1_50ms_pitch"
        goTest(fileName: fileName, xmlFileName: "900318")
        wait(for: [exp_Good1_B], timeout: 3)
    }
    
    func testGood2_B() { /// cumulativeScore:4535
        fileName = "houlai_good2_50ms_pitch"
        goTest(fileName: fileName, xmlFileName: "900318")
        wait(for: [exp_Good2_B], timeout: 3)
    }
    
    func goTest(fileName: String, xmlFileName: String) {
        vm = ScoringMachine()
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: xmlFileName, ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
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
                    vm.setPitch(speakerPitch: pitch, progressInMs: 0, score: 0)
                    i += 1
                }
            }
            usleep(5)
        }
    }
    
    private func parse(pitchFileString: String) -> [Double] {
        if pitchFileString.contains("\r\n") {
            let array = pitchFileString.split(separator: "\r\n").map({ Double($0)! })
            return array
        }
        else {
            let array = pitchFileString.split(separator: "\n").map({ Double($0)! })
            return array
        }
    }

    func sizeOfCanvasView(_ scoringMachine: ScoringMachineProtocol) -> CGSize {
        return .init(width: 380, height: 100)
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachineProtocol, didUpdateDraw standardInfos: [ScoringMachine.DrawInfo], highlightInfos: [ScoringMachine.DrawInfo]) {
        
    }
    
    func scoringMachine(_ scoringMachine: ScoringMachineProtocol, didUpdateCursor centerY: CGFloat, showAnimation: Bool, debugInfo: ScoringMachine.DebugInfo) {
        
    }
   
    func scoringMachine(_ scoringMachine: ScoringMachineProtocol,
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
            if cumulativeScore == 1943 {
                expBad1_A.fulfill()
            }
            if cumulativeScore == 1726 {
                expGood1_A.fulfill()
            }
            if cumulativeScore == 626 {
                expGood2_A.fulfill()
            }
            if cumulativeScore == 2283 {
                expGood3_A.fulfill()
            }
            if cumulativeScore == 2110 {
                expGood4_A.fulfill()
            }
            
            
            if cumulativeScore == 2953 {
                exp_Bad1_B.fulfill()
            }
            if cumulativeScore == 4454 {
                exp_Good1_B.fulfill()
            }
            if cumulativeScore == 4535 {
                exp_Good2_B.fulfill()
            }
            
            print("cumulativeScore:\(cumulativeScore)")
            print("---------\(fileName)  end ----------\n")
        }
    }
}
