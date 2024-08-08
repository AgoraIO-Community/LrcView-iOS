//
//  ScoringVMTest.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/2/1.
//

import XCTest
@testable import AgoraLyricsScore

class TestScoringVM: XCTestCase {

    func testCurrentIndexOfLine() throws {
        let vm = ScoringMachine()
        let lineEndTimes: [UInt] = [1000, 2000, 3000]
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
        
        /// 异常情况
        XCTAssertEqual(vm.calculatedY(pitch: 10, viewHeight: 0, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: 10, viewHeight: -10, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: 10, viewHeight: -10, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: -3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: -10, viewHeight: -10, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: -3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: -10, viewHeight: -10, minPitch: -100, maxPitch: 100, standardPitchStickViewHeight: -3), nil)
    }
    
    func testVoiceChange() {
        let changer = VoicePitchChanger()
        XCTAssertEqual(changer.handlePitch(stdPitch: 0, voicePitch: 0, stdMaxPitch: 400), 0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 1, voicePitch: 0, stdMaxPitch: 400), 0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 1, voicePitch: 1, stdMaxPitch: 400), 1)
        XCTAssertEqual(changer.handlePitch(stdPitch: 100, voicePitch: 90, stdMaxPitch: 400), 90.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 100, voicePitch: 80, stdMaxPitch: 400), 80.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 200, voicePitch: 80, stdMaxPitch: 400), 160.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 80, stdMaxPitch: 400), 320.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 200, stdMaxPitch: 400), 400.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 400, stdMaxPitch: 400), 400.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 500, stdMaxPitch: 400), 500.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 600, stdMaxPitch: 400), 300.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 700, stdMaxPitch: 400), 350.0)
        XCTAssertEqual(changer.handlePitch(stdPitch: 400, voicePitch: 800, stdMaxPitch: 400), 400.0)
    }
    
    func testCalculatedScore() {
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 201, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 200, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 190, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 180, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 0.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 170, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 9.763043)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 160, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 22.357689)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 150, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 35.765438)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 140, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 50.098568)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 130, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 65.494354)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 120, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 82.12307)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 110, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 100.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 101, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 100.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 100, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 100)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 99, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 100.0)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 80, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 73.64238)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 70, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 45.901512)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 60, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 13.877029)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 59, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 10.3853855)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 58, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 6.834053)
        XCTAssertEqual(ToneCalculator.calculedScore(voicePitch: 57, stdPitch: 100, scoreLevel: 10, scoreCompensationOffset: 0), 3.2209551)
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
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
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
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        let vm = ScoringMachine()
        let (_, infos) = ScoringMachine.createData(data: model)
        self.measure {
            let _ = vm.getHitedInfo(progress: 242000, currentVisiableInfos: infos)
        }
    }
    
    func testNoCrashWhenEndTimeGatterThanBeginTime() {
        /// 872957.xml 此文件中 97.316处，有异常。修复导致 crash
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "872957", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        let vm = ScoringMachine()
        let (_, infos) = ScoringMachine.createData(data: model)
        XCTAssertTrue(!infos.isEmpty)
    }
}
