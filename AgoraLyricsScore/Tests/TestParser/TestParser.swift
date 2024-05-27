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
        Log.setLoggers(loggers: [ConsoleLoggerEx()])
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
        XCTAssert(model.lines.count == 44)
        XCTAssert(model.lines.first!.beginTime == 1067)
        XCTAssert(model.name  == "十年")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.type  == .slow)
        XCTAssertEqual(model.duration, 381601)
        XCTAssert(model.preludeEndPosition  == 0)
        XCTAssertTrue(model.hasPitch == false)
    }
    
    func testKRCFile2() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "3017502026609527683", ofType: "krc")!)
        let data = try! Data(contentsOf: url)
        let p = KRCParser()
        guard let model = p.parse(krcFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 62)
        XCTAssert(model.lines.first!.beginTime == 0)
        XCTAssert(model.name  == "在你的身边")
        XCTAssert(model.singer  == "盛哲")
        XCTAssert(model.type  == .slow)
        XCTAssertEqual(model.duration, 253637+3117)
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
        XCTAssert(model.pitchDatas.count == 294)
        
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
        XCTAssert(model.lines.first!.beginTime == 1067)
        XCTAssert(model.name  == "十年")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.type  == .slow)
        XCTAssertEqual(model.duration, 381601)
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
    
    func testKrcEmptyPitchData() { /** EmptyPitchData **/
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133", ofType: "krc")!))
        
        guard let model = KaraokeViewEx.parseLyricData(krcFileData: krcFileData, pitchFileData: nil) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 44)
        XCTAssert(model.lines.first!.beginTime == 1067)
        XCTAssert(model.name  == "十年")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.type  == .slow)
        XCTAssertEqual(model.duration, 381601)
        XCTAssert(model.preludeEndPosition  == 0)
        XCTAssertTrue(model.hasPitch == false)
    }
    
    func testIncludeCopyrightSentence1() {
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133", ofType: "krc")!))
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        let model = KaraokeViewEx.parseLyricData(krcFileData: krcFileData,
                                                 pitchFileData: pitchFileData,
                                                 includeCopyrightSentence: false)
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.lines.count ?? 0, 40)
        XCTAssertEqual(model!.lines.first!.content, "如果那两个字没有颤抖")
        XCTAssertEqual(model?.copyrightSentenceLineCount ?? 0, 4)
    }
    
    func testIncludeCopyrightSentence2() {
        var krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "3017502026609527683", ofType: "krc")!))
        var pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "3017502026609527683.pitch", ofType: nil)!))
        var model = KaraokeViewEx.parseLyricData(krcFileData: krcFileData,
                                                 pitchFileData: pitchFileData,
                                                 includeCopyrightSentence: false)
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.lines.count ?? 0, 50)
        XCTAssertEqual(model!.lines.first!.content, "安静地又说分开")
        XCTAssertEqual(model?.copyrightSentenceLineCount ?? 0, 12)
        
        krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "5803512921786982975", ofType: "krc")!))
        pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "5803512921786982975.pitch", ofType: nil)!))
        model = KaraokeViewEx.parseLyricData(krcFileData: krcFileData,
                                                 pitchFileData: pitchFileData,
                                                 includeCopyrightSentence: false)
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.lines.count ?? 0, 58)
        XCTAssertEqual(model!.lines.first!.content, "不知道")
        XCTAssertEqual(model?.copyrightSentenceLineCount ?? 0, 7)
    }
    
    func testLineScoreRecorder() {
        let recoder = LineScoreRecorder()
        
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133", ofType: "krc")!))
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        
        let model = KaraokeViewEx.parseLyricData(krcFileData: krcFileData, pitchFileData: pitchFileData)!
        
        recoder.setLyricData(data: model)
        
        var score = recoder.setLineScore(index: 5, score: 1)
        XCTAssertEqual(score, 1)
        
        score = recoder.setLineScore(index: 6, score: 2)
        XCTAssertEqual(score, 1+2)
        
        score = recoder.setLineScore(index: 7, score: 3)
        XCTAssertEqual(score, 1+2+3)

        score = recoder.setLineScore(index: 8, score: 4)
        XCTAssertEqual(score, 1+2+3+4)
        
        /// index = 6
        score = recoder.seek(position: 22563)
        XCTAssertEqual(score, 1)
        
        /// index = 8
        score = recoder.seek(position: 30771)
        XCTAssertEqual(score, 1)
        
        /// index = 5
        score = recoder.seek(position: 19044)
        XCTAssertEqual(score, 0)
        
        /**
         ▿ 44 elements
           - 0 : "0"
           - 1 : "119"
           - 2 : "789"
           - 3 : "11590"
           - 4 : "15457"
           - 5 : "19192"
           - 6 : "22563"
           - 7 : "26163"
           - 8 : "30771"
           - 9 : "34841"
           - 10 : "37882"
           - 11 : "41753"
           - 12 : "47491"
           - 13 : "50912"
           - 14 : "53808"
           - 15 : "61002"
           - 16 : "62970"
           - 17 : "64906"
           - 18 : "66842"
           - 19 : "69242"
           - 20 : "73066"
           - 21 : "76546"
           - 22 : "78418"
           - 23 : "80371"
           - 24 : "82338"
           - 25 : "84756"
           - 26 : "88627"
           - 27 : "117165"
           - 28 : "120606"
           - 29 : "123563"
           - 30 : "130796"
           - 31 : "132683"
           - 32 : "134619"
           - 33 : "136475"
           - 34 : "138909"
           - 35 : "142812"
           - 36 : "146236"
           - 37 : "150075"
           - 38 : "154411"
           - 39 : "158316"
           - 40 : "168090"
           - 41 : "172384"
           - 42 : "175248"
           - 43 : "179088"
         */
    }
}
