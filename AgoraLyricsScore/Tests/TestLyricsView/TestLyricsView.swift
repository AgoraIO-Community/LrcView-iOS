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

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
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
        
        XCTAssertNotNil(LyricMachine.calculateProgressRate(progress: 43285, model: line))
        XCTAssertNil(LyricMachine.calculateProgressRate(progress: 43295, model: line))
        XCTAssertNotNil(LyricMachine.calculateProgressRate(progress: 43795, model: line))
    }

}
