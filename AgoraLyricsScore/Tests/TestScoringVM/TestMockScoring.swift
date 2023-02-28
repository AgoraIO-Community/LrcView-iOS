//
//  TestMockScoring.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/2/9.
//

import XCTest
@testable import AgoraLyricsScore

class TestMockScoring: XCTestCase, ScoringVMDelegate {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    var cumulativeScore = 0
    func testAll() {
        KaraokeView.setLog(printToConsole: true, writeToFile: true)

        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "825003", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        let vm = ScoringVM()
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

        XCTAssertEqual(cumulativeScore, 493)
    }

    func scoringVM(_ vm: ScoringVM, didFinishLineWith model: LyricLineModel, score: Int, cumulativeScore: Int, lineIndex: Int, lineCount: Int) {
        self.cumulativeScore = cumulativeScore
        print("didFinishLineWith score: \(score)")
    }

    func sizeOfCanvasView(_ vm: ScoringVM) -> CGSize {
        return .init(width: 380, height: 100)
    }

    func scoringVM(_ vm: ScoringVM, didUpdateDraw standardInfos: [ScoringVM.DrawInfo], highlightInfos: [ScoringVM.DrawInfo]) {}

    func scoringVM(_ vm: ScoringVM, didUpdateCursor centerY: CGFloat, showAnimation: Bool, debugInfo: ScoringVM.DebugInfo) {}

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
