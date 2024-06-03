//
//  TestLineScoreRecorder.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2024/6/3.
//

import XCTest
@testable import AgoraLyricsScore
final class TestLineScoreRecorder: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLineScoreRecorder() {
        let recoder = LineScoreRecorder()
        
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133", ofType: "krc")!))
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        
        let model = KaraokeView.parseLyricData(lyricFileData: krcFileData, pitchFileData: pitchFileData)!
        
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
