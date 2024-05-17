//
//  ScoringVMTest.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/2/1.
//

import XCTest
@testable import AgoraLyricsScoreEx

class TestScoringVM: XCTestCase {
    
    override func setUpWithError() throws {
        Log.setLoggers(loggers: [ConsoleLoggerEx()])
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
    
    func testCalculatedY() {
        let vm = ScoringMachine()
        let standardPitchStickViewHeight: CGFloat = 3
        let extend: CGFloat = standardPitchStickViewHeight
        let viewHeight: CGFloat = 100
        let minPitch: CGFloat = 0
        let maxPitch: CGFloat = 100
        XCTAssertEqual(vm.calculatedY(pitch: -1,
                                      viewHeight: viewHeight,
                                      minPitch: minPitch,
                                      maxPitch: maxPitch,
                                      standardPitchStickViewHeight: standardPitchStickViewHeight), 100-extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: -2, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), 100-extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: 0, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), 100-extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: 101, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: 102, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), extend/2)
        
        XCTAssertEqual(vm.calculatedY(pitch: 99, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), 2.469999999999999)
        XCTAssertEqual(vm.calculatedY(pitch: 75, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), 25.75)
        XCTAssertEqual(vm.calculatedY(pitch: 50, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), 50)
        XCTAssertEqual(vm.calculatedY(pitch: 25, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), 74.25)
        XCTAssertEqual(vm.calculatedY(pitch: 10, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), 88.8)
        XCTAssertEqual(vm.calculatedY(pitch: 5, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), 93.65)
        XCTAssertEqual(vm.calculatedY(pitch: 1, viewHeight: viewHeight, minPitch: minPitch, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), 97.53)
        
        /// 异常情况
        XCTAssertEqual(vm.calculatedY(pitch: 10, viewHeight: 0, minPitch: 0, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), nil)
        XCTAssertEqual(vm.calculatedY(pitch: 10, viewHeight: -10, minPitch: 0, maxPitch: maxPitch, standardPitchStickViewHeight: standardPitchStickViewHeight), nil)
        XCTAssertEqual(vm.calculatedY(pitch: 10, viewHeight: -10, minPitch: 0, maxPitch: maxPitch, standardPitchStickViewHeight: -3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: -10, viewHeight: -10, minPitch: 0, maxPitch: maxPitch, standardPitchStickViewHeight: -3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: -10, viewHeight: -10, minPitch: -100, maxPitch: maxPitch, standardPitchStickViewHeight: -3), nil)
    }
    
    func calculatePercentage(value: Float) -> Double {
        let rate: Double = Double(value) / Double(100.0)
        return rate
    }
    
    func testCalculatedYWithScore() {
        let vm = ScoringMachine()
        let standardPitchStickViewHeight: CGFloat = 3
        let extend: CGFloat = standardPitchStickViewHeight
        let viewHeight: CGFloat = 100
        let minPitch: CGFloat = 0
        let maxPitch: CGFloat = 100
        XCTAssertEqual(vm.calculatedY(pitch: -100,
                                      viewHeight: viewHeight,
                                      minPitch: minPitch,
                                      maxPitch: maxPitch,
                                      standardPitchStickViewHeight: standardPitchStickViewHeight), 100-extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: -200,
                                      viewHeight: viewHeight,
                                      minPitch: minPitch,
                                      maxPitch: maxPitch,
                                      standardPitchStickViewHeight: standardPitchStickViewHeight), 100-extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: 0,
                                      viewHeight: viewHeight,
                                      minPitch: minPitch,
                                      maxPitch: maxPitch,
                                      standardPitchStickViewHeight: standardPitchStickViewHeight), 100-extend/2)
        XCTAssertEqual(vm.calculatedY(pitch: 99,
                                      viewHeight: viewHeight,
                                      minPitch: minPitch,
                                      maxPitch: maxPitch,
                                      standardPitchStickViewHeight: standardPitchStickViewHeight), 2.469999999999999)
        XCTAssertEqual(vm.calculatedY(pitch: 75,
                                      viewHeight: viewHeight,
                                      minPitch: minPitch,
                                      maxPitch: maxPitch,
                                      standardPitchStickViewHeight: standardPitchStickViewHeight), 25.75)
        XCTAssertEqual(vm.calculatedY(pitch: 50,
                                      viewHeight: viewHeight,
                                      minPitch: minPitch,
                                      maxPitch: maxPitch,
                                      standardPitchStickViewHeight: standardPitchStickViewHeight), 50)
        XCTAssertEqual(vm.calculatedY(pitch: 25,
                                      viewHeight: viewHeight,
                                      minPitch: minPitch,
                                      maxPitch: maxPitch,
                                      standardPitchStickViewHeight: standardPitchStickViewHeight), 74.25)
        XCTAssertEqual(vm.calculatedY(pitch: 10,
                                      viewHeight: viewHeight,
                                      minPitch: minPitch,
                                      maxPitch: maxPitch,
                                      standardPitchStickViewHeight: standardPitchStickViewHeight), 88.8)

        /// 异常情况
        XCTAssertEqual(vm.calculatedY(pitch: 0.1, viewHeight: 0, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: 0.1, viewHeight: -10, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: 3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: 0.1, viewHeight: -10, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: -3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: -0.1, viewHeight: -10, minPitch: 0, maxPitch: 100, standardPitchStickViewHeight: -3), nil)
        XCTAssertEqual(vm.calculatedY(pitch: -0.1, viewHeight: -10, minPitch: -100, maxPitch: 100, standardPitchStickViewHeight: -3), nil)
    }
    
    func testHit() {
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.krc", ofType: nil)!))
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        
        guard let model = KaraokeViewEx.parseLyricData(krcFileData: krcFileData,
                                                     pitchFileData: pitchFileData) else {
            XCTFail()
            return
        }
        let vm = ScoringMachine()
        let (_, infos) = ScoringMachine.createData(data: model)
        XCTAssertNil(vm.getHitedInfo(progress: 0, currentVisiableInfos: infos))
        XCTAssertNil(vm.getHitedInfo(progress: 28813, currentVisiableInfos: infos))
        XCTAssertEqual(vm.getHitedInfo(progress: 41753, currentVisiableInfos: infos)!.pitch, 18)
        XCTAssertEqual(vm.getHitedInfo(progress: 50912, currentVisiableInfos: infos)!.pitch, 50)
        XCTAssertEqual(vm.getHitedInfo(progress: 69242, currentVisiableInfos: infos)!.pitch, 50)
        XCTAssertEqual(vm.getHitedInfo(progress: 73066, currentVisiableInfos: infos)!.pitch, 50)
    }
    
    func testCalculateActualSpeakerPitch() {
        let vm = ScoringMachine()
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 1, refPitch: 50), 50-2)
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 2, refPitch: 50), 50-1)
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 3, refPitch: 50), 50)
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 4, refPitch: 50), 50+1)
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 5, refPitch: 50), 50+2)
    }
    
    func testPerformanceExample() throws {
        
    }
}
