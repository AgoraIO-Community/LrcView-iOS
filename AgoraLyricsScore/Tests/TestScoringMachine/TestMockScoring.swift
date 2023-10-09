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
