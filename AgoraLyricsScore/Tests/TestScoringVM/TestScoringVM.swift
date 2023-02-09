//
//  ScoringVMTest.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/2/1.
//

import XCTest
@testable import AgoraLyricsScore

class TestScoringVM: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCurrentIndexOfLine() throws {
        let vm = ScoringVM()
        let lineEndTimes = [1000, 2000, 3000]
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 0, lineEndTimes: lineEndTimes), 0)
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 999, lineEndTimes: lineEndTimes), 0)
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 1000, lineEndTimes: lineEndTimes), 0)
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 1001, lineEndTimes: lineEndTimes), 1)
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 1999, lineEndTimes: lineEndTimes), 1)
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 2000, lineEndTimes: lineEndTimes), 1)
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 2001, lineEndTimes: lineEndTimes), 2)
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 2999, lineEndTimes: lineEndTimes), 2)
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 3000, lineEndTimes: lineEndTimes), 2)
        XCTAssertEqual(vm.findCurrentIndexOfLine(progress: 3001, lineEndTimes: lineEndTimes), 3)
    }
    
    func testCalculatedCumulativeScore() throws {
        let vm = ScoringVM()
        let lineScores = [10, 20, 5]
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: -1, lineScores: lineScores), 0)
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: 0, lineScores: lineScores), 10)
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: 1, lineScores: lineScores), 10+20)
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: 2, lineScores: lineScores), 10+20+5)
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: 3, lineScores: lineScores), 10+20+5)
    }
    
    func testGetCenterY() {
        let vm = ScoringVM()
        let standardPitchStickViewHeight: CGFloat = 3
        let extend: CGFloat = standardPitchStickViewHeight
        
        XCTAssertEqual(vm.calculatedY(pitch: -1, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 100-extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: -2, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 100-extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: 0, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 100-extend/2)

        XCTAssertEqual(vm.calculatedY(pitch: 101, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: 102, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), extend/2)
        
        XCTAssertEqual(vm.calculatedY(pitch: 99, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 2.469999999999999)
        XCTAssertEqual(vm.calculatedY(pitch: 75, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 25.75)
        XCTAssertEqual(vm.calculatedY(pitch: 50, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 50)
        XCTAssertEqual(vm.calculatedY(pitch: 25, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 74.25)
        XCTAssertEqual(vm.calculatedY(pitch: 10, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 88.8)
        XCTAssertEqual(vm.calculatedY(pitch: 5, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 93.65)
        XCTAssertEqual(vm.calculatedY(pitch: 1, viewHeight: 100, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), 97.53)
    }
    
    func testHit() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "745012", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        let vm = ScoringVM()
        let (_, infos) = ScoringVM.createData(data: model)
        XCTAssertNil(vm.getHitedInfo(progress: 0, currentVisiableInfos: infos, pitchDuration: 50))
        
    }
}
