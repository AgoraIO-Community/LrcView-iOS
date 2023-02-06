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
    }
    
    func testGetCenterY() {
//        let vm = ScoringVM()
//        let max = 100 + 1.5
//        let min = 0 - 1.5
//
//
//        XCTAssertEqual(vm.getY(pitch: 1, canvasViewSize: .init(width: 390, height: 100), minPitch: min, maxPitch: max), 1 + 1.5)
//        XCTAssertEqual(vm.getY(pitch: 100, canvasViewSize: .init(width: 390, height: 100), minPitch: min, maxPitch: max), 100 - 1.5)
        
    }
}
