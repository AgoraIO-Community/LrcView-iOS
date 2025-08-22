//
//  TestScoringMachineEx.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2024/6/4.
//

import XCTest
@testable import AgoraLyricsScore

class TestScoringMachineEx: XCTestCase {
    
    override func setUpWithError() throws {
        Log.setLoggers(loggers: [ConsoleLogger()])
    }
    
    func testCurrentIndexOfLine() throws {
        let vm = ScoringMachineEx()
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
        let vm = ScoringMachineEx()
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
        let vm = ScoringMachineEx()
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
        
        guard let model = KaraokeView.parseLyricData(lyricFileData: krcFileData, pitchFileData: pitchFileData, includeCopyrightSentence: false) else {
            XCTFail()
            return
        }
        let vm = ScoringMachineEx()
        let (_, infos) = ScoringMachineEx.createData(data: model)
        XCTAssertNil(vm.getHitedInfo(progress: 0, currentVisiableInfos: infos))
        XCTAssertNil(vm.getHitedInfo(progress: 28813, currentVisiableInfos: infos))
        XCTAssertEqual(vm.getHitedInfo(progress: 41753, currentVisiableInfos: infos)!.pitch, 18)
        XCTAssertEqual(vm.getHitedInfo(progress: 50912, currentVisiableInfos: infos)!.pitch, 50)
        XCTAssertEqual(vm.getHitedInfo(progress: 69242, currentVisiableInfos: infos)!.pitch, 50)
        XCTAssertEqual(vm.getHitedInfo(progress: 73066, currentVisiableInfos: infos)!.pitch, 50)
    }
    
    func testCalculateActualSpeakerPitch() {
        let vm = ScoringMachineEx()
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 1, refPitch: 50), 50-2)
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 2, refPitch: 50), 50-1)
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 3, refPitch: 50), 50)
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 4, refPitch: 50), 50+1)
        XCTAssertEqual(vm.calculateActualSpeakerPitch(speakerPitch: 5, refPitch: 50), 50+2)
    }

        /// 测试新的分层打分逻辑
    func testCalculateScoreAfterNormalization() {
        let vm = ScoringMachineEx()
        
        // 测试完全匹配的情况
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 100.0, refPitch: 100.0), 100)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 50.0, refPitch: 50.0), 100)
        
        // 测试差异为1的情况
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 101.0, refPitch: 100.0), 90)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 99.0, refPitch: 100.0), 90)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 51.0, refPitch: 50.0), 90)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 49.0, refPitch: 50.0), 90)
        
        // 测试差异为2的情况
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 102.0, refPitch: 100.0), 80)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 98.0, refPitch: 100.0), 80)
        
        // 测试差异为3的情况
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 103.0, refPitch: 100.0), 70)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 97.0, refPitch: 100.0), 70)
        
        // 测试差异为4的情况
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 104.0, refPitch: 100.0), 60)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 96.0, refPitch: 100.0), 60)
        
        // 测试差异为5的情况
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 105.0, refPitch: 100.0), 50)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 95.0, refPitch: 100.0), 50)
        
        // 测试差异大于5的情况
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 106.0, refPitch: 100.0), 0)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 94.0, refPitch: 100.0), 0)
        XCTAssertEqual(vm.calculateScoreAfterNormalization(speakerPitch: 200.0, refPitch: 100.0), 0)
    }
}

