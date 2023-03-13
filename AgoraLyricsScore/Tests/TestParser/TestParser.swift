//
//  TestBoard.swift
//  AgoraMeetingCore-Unit-Tests
//
//  Created by ZYP on 2021/6/29.
//

import XCTest
@testable import AgoraLyricsScore

class TestParser: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLrcFile() throws { /** lrc normal **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "lrc", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.content.contains("什么是幸福 "))
    }
    
    func testXMLFile() throws { /** xml normal **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "745012", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.beginTime == 18487)
        XCTAssert(model.name  == "十年 ")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.type  == .fast)
        XCTAssert(model.duration  == 186022)
        XCTAssert(model.preludeEndPosition  == 18487)
        XCTAssertTrue(model.hasPitch)
    }
    
    func testEmptyData() { /** EmptyData **/
        let data = Data()
        let model = KaraokeView.parseLyricData(data: data)
        XCTAssertNil(model)
    }
    
    func testSubData() { /** SubData **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "lrc", ofType: "lrc")!)
        var data = try! Data(contentsOf: url)
        data = data.subdata(in: 90...100)
        let model = KaraokeView.parseLyricData(data: data)
        XCTAssertNil(model)
    }
    
    func testTimeIssue1() { /** xml 异常 时间严重异常 **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "CJ1420023417", ofType: "xml")!)
        let data = try! Data(contentsOf: url)

        let parser = Parser()
        let model = parser.parseLyricData(data: data)
        XCTAssertNil(model)
    }
    
    func testTimeIssue2() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "745012-timeissue2", ofType: "xml")!)
        let data = try! Data(contentsOf: url)

        let parser = Parser()
        let model = parser.parseLyricData(data: data)
        XCTAssertNotNil(model)
        
        let infos = ScoringMachine.createData(data: model!)
        
        var pre:ScoringMachine.Info?
        
        for info in infos.1 {
            if let pre = pre, info.beginTime < pre.endTime {
                let text = """
                --> error
                current: \(info.word) beginTime:\(info.beginTime) endTime:\(info.endTime)
                pre: \(pre.word) beginTime:\(pre.beginTime) endTime:\(info.endTime)
                """
                print(text)
                XCTFail()
            }
            pre = info
        }
    }
    
    func testOneline() throws { /** Oneline **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "810507-oneline", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.beginTime == 28970)
    }
    
    func testNoWordInTone() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "noWordInTone", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines[0].tones[0].beginTime == 34129)
        XCTAssert(model.lines[0].tones[1].word  == "")
        XCTAssert(model.lines[0].tones[2].word  == "响")
    }
}
