//
//  VoicePitchChangerTests.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/2/10.
//

import XCTest
@testable import AgoraLyricsScore

class VoicePitchChangerTests: XCTestCase {

    var voicePitchChanger: VoicePitchChanger!

    override func setUp() {
        voicePitchChanger = VoicePitchChanger()
    }

    override func tearDown() {
        voicePitchChanger = nil
    }

    func testHandlePitch_WhenVoicePitchIsZero_ShouldReturnZero() {
        let result = voicePitchChanger.handlePitch(stdPitch: 60, voicePitch: 0, stdMaxPitch: 70)
        XCTAssertEqual(result, 0)
    }
    
    func testHandlePitch_WhenVoicePitchIsLessThanStdPitch_ShouldReturnCorrectValue() {
            let result = voicePitchChanger.handlePitch(stdPitch: 60, voicePitch: 55, stdMaxPitch: 70)
            print("result: \(result), expected: 57.5")
            XCTAssertEqual(result, 57.5)
        }
    
    func testHandlePitch_WhenVoicePitchIsGreaterThanStdPitch_ShouldReturnCorrectValue() {
        let result = voicePitchChanger.handlePitch(stdPitch: 60, voicePitch: 65, stdMaxPitch: 70)
        XCTAssertEqual(result, 62.5)
    }
    
    func testHandlePitch_WhenVoicePitchIsGreaterThanStdMaxPitch_ShouldReturnStdMaxPitch() {
        let result = voicePitchChanger.handlePitch(stdPitch: 60, voicePitch: 80, stdMaxPitch: 70)
        XCTAssertEqual(result, 70)
    }
    
    func testHandlePitch_WhenToneDifferenceIsLessThanHalf_ShouldReturnVoicePitch() {
        voicePitchChanger.offset = 1
        voicePitchChanger.n = 1
        let result = voicePitchChanger.handlePitch(stdPitch: 60, voicePitch: 61, stdMaxPitch: 70)
        XCTAssertEqual(result, 61)
    }
    
    func testReset_ShouldResetOffsetAndNToZero() {
        voicePitchChanger.offset = 1
        voicePitchChanger.n = 1
        voicePitchChanger.reset()
        XCTAssertEqual(voicePitchChanger.offset, 0)
        XCTAssertEqual(voicePitchChanger.n, 0)
    }
}
