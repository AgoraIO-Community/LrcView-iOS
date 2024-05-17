//
//  TestBoard.swift
//  AgoraMeetingCore-Unit-Tests
//
//  Created by ZYP on 2021/6/29.
//

import XCTest
@testable import AgoraLyricsScoreEx

class TestParser: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func testKRCFile() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133", ofType: "krc")!)
        let data = try! Data(contentsOf: url)
        let p = KRCParser()
        guard let model = p.parse(krcFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.beginTime == 0)
        XCTAssert(model.name  == "十年 (《明年今日》国语版|《隐婚男女》电影插曲|《摆渡人》电影插曲)")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.type  == .slow)
        XCTAssertEqual(model.duration, 182736)
        XCTAssert(model.preludeEndPosition  == 0)
        XCTAssertTrue(model.hasPitch == false)
    }
    
    func testPitchParser() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!)
        let data = try! Data(contentsOf: url)
        let p = PitchParser()
        guard let model = p.parse(fileContent: data)else {
            XCTFail()
            return
        }
        XCTAssert(model.pitchDatas.count  == 294)
        
        XCTAssert(model.pitchDatas.first!.duration == 241)
        XCTAssert(model.pitchDatas.first!.startTime == 15203)
        XCTAssert(model.pitchDatas.first!.pitch == 50)
        
        XCTAssert(model.pitchDatas.last!.duration == 2907)
        XCTAssert(model.pitchDatas.last!.startTime == 180203)
        XCTAssert(model.pitchDatas.last!.pitch == 50)
    }
    
    func testKrcPitchMerge() {
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133", ofType: "krc")!))
        
        
        let p = Parser()
        guard let model = p.parseLyricData(krcFileData: krcFileData, pitchFileData: pitchFileData) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.beginTime == 0)
        XCTAssert(model.name  == "十年 (《明年今日》国语版|《隐婚男女》电影插曲|《摆渡人》电影插曲)")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.type  == .slow)
        XCTAssertEqual(model.duration, 182736)
        XCTAssert(model.preludeEndPosition  == 15203)
        XCTAssertTrue(model.hasPitch == true)
        
        XCTAssert(model.pitchDatas.count  == 294)
        XCTAssert(model.pitchDatas.first!.duration == 241)
        XCTAssert(model.pitchDatas.first!.startTime == 15203)
        XCTAssert(model.pitchDatas.first!.pitch == 50)
        XCTAssert(model.pitchDatas.last!.duration == 2907)
        XCTAssert(model.pitchDatas.last!.startTime == 180203)
        XCTAssert(model.pitchDatas.last!.pitch == 50)
    }
    
    func testKrcEmptyData() { /** EmptyData **/
        let data = Data()
        let model = KaraokeViewEx.parseLyricData(krcFileData: data, pitchFileData: data)
        XCTAssertNil(model)
    }
}
