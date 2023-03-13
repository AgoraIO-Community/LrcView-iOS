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
        let vm = ScoringMachine()
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
        let vm = ScoringMachine()
        let lineScores = [10, 20, 5]
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: -1, lineScores: lineScores), 0)
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: 0, lineScores: lineScores), 10)
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: 1, lineScores: lineScores), 10+20)
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: 2, lineScores: lineScores), 10+20+5)
        XCTAssertEqual(vm.calculatedCumulativeScore(indexOfLine: 3, lineScores: lineScores), 10+20+5)
    }
    
    func testGetCenterY() {
        let vm = ScoringMachine()
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
    
    func testVoiceChange() {
        let changer = VoicePitchChanger()
        XCTAssertEqual(changer.handlePitch(stdPitch: 0, voicePitch: 0, stdMaxPitch: 400), 0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 1, voicePitch: 0, stdMaxPitch: 400), 0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 1, voicePitch: 1, stdMaxPitch: 400), 1)
        XCTAssertEqual(changer.handlePitch(stdPitch: 100, voicePitch: 90, stdMaxPitch: 400), 95)
        XCTAssertEqual(changer.handlePitch(stdPitch: 100, voicePitch: 80, stdMaxPitch: 400), 90)
        XCTAssertEqual(changer.handlePitch(stdPitch: 200, voicePitch: 80, stdMaxPitch: 400), 117.5)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 80, stdMaxPitch: 400), 174.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 200, stdMaxPitch: 400), 311.66666666666663)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 400, stdMaxPitch: 400), 400)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 500, stdMaxPitch: 400), 400.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 600, stdMaxPitch: 400), 400.0)
    }
    
    func testCalculatedScore() {
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 201, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 200, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 190, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 180, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 170, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 8.135873)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 160, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 18.63141)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 150, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 29.804527)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 140, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 41.74881)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 130, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 54.578625)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 120, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 68.43588)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 110, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 83.49959)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 101, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 98.27737)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 100, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 100)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 99, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 98.26005)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 80, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 61.36865)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 70, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 38.251263)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 60, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 11.564189)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 59, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 8.654488)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 58, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 5.695045)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 57, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 2.6841342)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 56, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 55, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 50, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 40, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 30, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 20, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 10, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 1, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0)
    }
    
    func testHit() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "825003", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        let vm = ScoringMachine()
        let (_, infos) = ScoringMachine.createData(data: model)
        XCTAssertNil(vm.getHitedInfo(progress: 0, currentVisiableInfos: infos))
        XCTAssertNil(vm.getHitedInfo(progress: 28813, currentVisiableInfos: infos))
        XCTAssertEqual(vm.getHitedInfo(progress: 28814, currentVisiableInfos: infos)!.pitch, 172)
        XCTAssertEqual(vm.getHitedInfo(progress: 29675, currentVisiableInfos: infos)!.pitch, 172)
        XCTAssertEqual(vm.getHitedInfo(progress: 185160, currentVisiableInfos: infos)!.pitch, 130)
        XCTAssertEqual(vm.getHitedInfo(progress: 185161, currentVisiableInfos: infos)!.pitch, 213)
    }
    
    func testPerformanceExample() throws {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "825003", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        let vm = ScoringMachine()
        let (_, infos) = ScoringMachine.createData(data: model)
        self.measure {
            let _ = vm.getHitedInfo(progress: 242000, currentVisiableInfos: infos)
        }
    }
}
