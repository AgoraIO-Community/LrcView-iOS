//
//  TestMerge.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/7/6.
//

import XCTest
@testable import AgoraLyricsScore

final class TestMerge: XCTestCase {
    
    func testIsEnhancedLrc() {
        let lrcParser = LrcParser()
        
        let url1 = URL(fileURLWithPath: Bundle.current.path(forResource: "lrc", ofType: "lrc")!)
        let data1 = try! Data(contentsOf: url1)
        let model1 = lrcParser.parseLyricData(data: data1)
        XCTAssert(PitchMerge.isEnhancedLrc(model: model1!) == false)
        
        let url2 = URL(fileURLWithPath: Bundle.current.path(forResource: "EnhancedLRCformat", ofType: "lrc")!)
        let data2 = try! Data(contentsOf: url2)
        let model2 = lrcParser.parseLyricData(data: data2)
        XCTAssert(PitchMerge.isEnhancedLrc(model: model2!) == true)
    }
    
}
