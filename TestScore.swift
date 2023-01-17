//
//  TestScore.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/1/16.
//

import XCTest
@testable import AgoraLyricsScore

class TestScore: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testVoiceChange() {
        let vpc = VoicePitchChanger()
        print(vpc.handlePitch(stdPitch: 300, voicePitch: 189, wordMaxPitch: 500))
        print(vpc.handlePitch(stdPitch: 310, voicePitch: 176, wordMaxPitch: 500))
        print(vpc.handlePitch(stdPitch: 320, voicePitch: 137, wordMaxPitch: 500))
        print(vpc.handlePitch(stdPitch: 390, voicePitch: 120, wordMaxPitch: 500))
        print(vpc.handlePitch(stdPitch: 430, voicePitch: 210, wordMaxPitch: 500))
        print(vpc.handlePitch(stdPitch: 460, voicePitch: 234, wordMaxPitch: 500))
        print(vpc.handlePitch(stdPitch: 490, voicePitch: 199, wordMaxPitch: 500))
        
/// 结果
//        300.0
//        298.5
//        279.6666666666667
//        294.5
//        393.6
//        424.66666666666663
//        399.0
    }
    
    func testCalcultedTone() {
        print(AgoraKaraokeScoreView.calcultedTone(stdPitch: 300, pitchMin: 0, pitchMax: 500, pitch: 500, level: 10, offset: 0, lineCalcuScore: 100))
        print(AgoraKaraokeScoreView.calcultedTone(stdPitch: 300, pitchMin: 0, pitchMax: 500, pitch: 400, level: 10, offset: 0, lineCalcuScore: 100))
        print(AgoraKaraokeScoreView.calcultedTone(stdPitch: 300, pitchMin: 0, pitchMax: 500, pitch: 301, level: 10, offset: 0, lineCalcuScore: 100))
        print(AgoraKaraokeScoreView.calcultedTone(stdPitch: 300, pitchMin: 0, pitchMax: 500, pitch: 300, level: 10, offset: 0, lineCalcuScore: 100))
        print(AgoraKaraokeScoreView.calcultedTone(stdPitch: 300, pitchMin: 0, pitchMax: 500, pitch: 299, level: 10, offset: 0, lineCalcuScore: 100))
        print(AgoraKaraokeScoreView.calcultedTone(stdPitch: 300, pitchMin: 0, pitchMax: 500, pitch: 200, level: 10, offset: 0, lineCalcuScore: 100))
        print(AgoraKaraokeScoreView.calcultedTone(stdPitch: 300, pitchMin: 0, pitchMax: 500, pitch: 100, level: 10, offset: 0, lineCalcuScore: 100))
        print(AgoraKaraokeScoreView.calcultedTone(stdPitch: 300, pitchMin: 0, pitchMax: 500, pitch: 50, level: 10, offset: 0, lineCalcuScore: 100))
        print(AgoraKaraokeScoreView.calcultedTone(stdPitch: 300, pitchMin: 0, pitchMax: 500, pitch: 1, level: 10, offset: 0, lineCalcuScore: 100))
        
///结果
//        11.564141395769767
//        50.195508021360126
//        99.42388175378764
//        100.0
//        99.4219581504183
//        29.804515783103046
//        0.0
//        0.0
//        0.0

    }
}
