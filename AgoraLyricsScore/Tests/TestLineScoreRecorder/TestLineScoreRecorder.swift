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
        Log.setLoggers(loggers: [ConsoleLogger()])
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
        
        /// index = 8
        score = recoder.seek(position: 30572)
        XCTAssertEqual(score, 1+2+3)
        
        /// index = 6
        score = recoder.seek(position: 22638)
        XCTAssertEqual(score, 1)
        
        /// index = 5
        score = recoder.seek(position: 19044)
        XCTAssertEqual(score, 0)
        
        /** line begainTime
         - 0 : 1067
         - 1 : 1720
         - 2 : 1870
         - 3 : 2173
         - 4 : 15106
         - 5 : 19044
         - 6 : 22638
         - 7 : 25955
         - 8 : 30572
         - 9 : 34724
         - 10 : 37621
         - 11 : 41673
         - 12 : 47453
         - 13 : 50725
         - 14 : 53597
         - 15 : 60854
         - 16 : 62717
         - 17 : 64580
         - 18 : 66642
         - 19 : 69058
         - 20 : 72791
         - 21 : 76369
         - 22 : 78082
         - 23 : 80050
         - 24 : 82165
         - 25 : 84532
         - 26 : 88308
         - 27 : 117010
         - 28 : 120282
         - 29 : 123250
         - 30 : 130478
         - 31 : 132445
         - 32 : 134410
         - 33 : 136321
         - 34 : 138689
         - 35 : 142461
         - 36 : 146035
         - 37 : 149712
         - 38 : 154196
         - 39 : 158071
         - 40 : 168121
         - 41 : 172203
         - 42 : 175070
         - 43 : 178917
         */
    }

}
