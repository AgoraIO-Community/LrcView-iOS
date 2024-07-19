//
//  TestLrcParser.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/7/5.
//

import XCTest
@testable import AgoraLyricsScore

final class TestLrcParser: XCTestCase {

    func testLrcParseOfEnhancedFormat() { /** ablout enhancedFormat **/
        let lrcParser = LrcParser()
        
        let sampleFormat1 = "[00:22.30]我不会发现 我难受"
        let sampleFormat2 = "[00:25.745]怎么说出口"
        let enhancedFormat1 = "[00:23.997]<00:23.997>又<00:24.694>是<00:25.356>九<00:25.704>月<00:26.017>九<00:26.644>重<00:27.028>阳<00:27.376>夜<00:28.003>难<00:28.351>聚<00:28.665>首"
        let enhancedFormat2 = "[00:29.326]<00:29.326>思<00:30.023>乡<00:30.476>的<00:30.719>人<00:31.416>儿<00:32.008>飘<00:32.322>流<00:32.705>在<00:33.053>外<00:33.332>头"
        let enhancedFormat3 = "[00:34.690]<00:34.690>又<00:35.352>是<00:36.014>九<00:36.327>月<00:36.675>九<00:37.337>愁<00:37.685>更<00:38.034>愁<00:38.661>情<00:39.009>更<00:39.392>忧"
        let enhancedFormat4 = "[00:53.011]<00:53.011> Why<00:53.015> hh"
        
        XCTAssertFalse(lrcParser.containsWordStartTime(sampleFormat1))
        XCTAssertFalse(lrcParser.containsWordStartTime(sampleFormat2))
        XCTAssertTrue(lrcParser.containsWordStartTime(enhancedFormat1))
        XCTAssertTrue(lrcParser.containsWordStartTime(enhancedFormat2))
        XCTAssertTrue(lrcParser.containsWordStartTime(enhancedFormat3))
        XCTAssertTrue(lrcParser.containsWordStartTime(enhancedFormat4))

        let tones1 = lrcParser.parseLineStringOfEnhancedFormat(enhancedFormat1)
        XCTAssertTrue(tones1.map({ $0.word }).joined() == "又是九月九重阳夜难聚首")
        XCTAssertTrue(tones1[0].beginTime == 23 * 1000 + 997)
        XCTAssertTrue(tones1[0].duration == (24 * 1000 + 694) - (23 * 1000 + 997))
        XCTAssertTrue(tones1[1].beginTime == 24 * 1000 + 694)
        XCTAssertTrue(tones1[1].duration == (25 * 1000 + 356) - (24 * 1000 + 694))
        XCTAssertTrue(tones1[10].beginTime == 28 * 1000 + 665)
        XCTAssertTrue(tones1[10].duration == 0)

        let tones2 = lrcParser.parseLineStringOfEnhancedFormat(enhancedFormat2)
        XCTAssertTrue(tones2.map({ $0.word }).joined() == "思乡的人儿飘流在外头")
        XCTAssertTrue(tones2[0].beginTime == 29 * 1000 + 326)
        XCTAssertTrue(tones2[0].duration == (30 * 1000 + 23) - (29 * 1000 + 326))
        XCTAssertTrue(tones2[9].duration == 0)
        
        let tones4 = lrcParser.parseLineStringOfEnhancedFormat(enhancedFormat4)
        XCTAssertEqual(tones4[0].word, " Why")
        XCTAssertEqual(tones4[0].beginTime, 53 * 1000 + 11)
        XCTAssertEqual(tones4[1].word, " hh")
        XCTAssertEqual(tones4[1].beginTime, 53 * 1000 + 15)
    }
    
    func testTimeParae() {
        let lrcParser = LrcParser()
        XCTAssertTrue(lrcParser.parseTime("00:24.694") == 24694)
        XCTAssertTrue(lrcParser.parseTime("01:02.345") == 62345)
        XCTAssertTrue(lrcParser.parseTime("01:02.45") == 62045)
        XCTAssertTrue(lrcParser.parseTime("00:00.000") == 0)
        XCTAssertTrue(lrcParser.parseTime("00:53.011") == 53 * 1000 + 11)
    }

}
