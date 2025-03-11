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
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "153378", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        
        let dataList = model.lines.map({ LyricCellRoll.Model(text: $0.content,
                                                        progressRate: 0,
                                                        beginTime: $0.beginTime,
                                                        duration: $0.duration,
                                                        status: .normal,
                                                        tones: $0.tones) })
        let line = dataList[3]
        
        XCTAssertNotNil(LyricMachine.calculateProgressRate(progress: 43285, model: line, scrollByWord: true))
        XCTAssertNil(LyricMachine.calculateProgressRate(progress: 43295, model: line, scrollByWord: true))
        XCTAssertNotNil(LyricMachine.calculateProgressRate(progress: 43795, model: line, scrollByWord: true))
    }

}
