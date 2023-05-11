//
//  TestLyricsView.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/2/17.
//

import XCTest
@testable import AgoraLyricsScore

class TestLyricsView: XCTestCase {
    func testLyricsToneSpace() { /** 测试计算进度算法，tone之间有空隙 **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "153378", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        
        let dataList = model.lines.map({ LyricCell.Model(text: $0.content,
                                                        progressRate: 0,
                                                        beginTime: $0.beginTime,
                                                        duration: $0.duration,
                                                        status: .normal,
                                                        tones: $0.tones) })
        let line = dataList[3]
        XCTAssertNotNil(LyricMachine.calculateProgressRate(progress: 43285, model: line, isTimeAccurateToWord: true))
        XCTAssertNotNil(LyricMachine.calculateProgressRate(progress: 43295, model: line, isTimeAccurateToWord: true))
        XCTAssertNotNil(LyricMachine.calculateProgressRate(progress: 43795, model: line, isTimeAccurateToWord: true))
    }

}
