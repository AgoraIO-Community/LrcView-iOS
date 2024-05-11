//
//  TestLyricsView.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/2/17.
//

import XCTest
@testable import AgoraLyricsScore

class TestLyricsView: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLyricsToneSpace() { /** 测试计算进度算法，tone之间有空隙 **/
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.krc", ofType: nil)!))
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        
        guard let model = KaraokeView.parseLyricData(krcFileData: krcFileData,
                                                     pitchFileData: pitchFileData,
                                                     includeCopyrightSentence: false) else {
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
        
        XCTAssertNil(LyricMachine.calculateProgressRate(progress: 0, model: line, canScoring: true))
        XCTAssertNotNil(LyricMachine.calculateProgressRate(progress: line.beginTime + 30, model: line, canScoring: true))
        XCTAssertNotNil(LyricMachine.calculateProgressRate(progress: line.beginTime + 60, model: line, canScoring: true))
        XCTAssertEqual(LyricMachine.calculateProgressRate(progress: 26596+191, model: line, canScoring: true), 0.5)
    }

}
