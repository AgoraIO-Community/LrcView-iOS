//
//  TestScoreAlgorithm.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/1/28.
//

import XCTest
@testable import AgoraLyricsScore

class TestScoreAlgorithm: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTotalGradeIndex() throws {
        let sa = ScoreAlgorithm()
        XCTAssertNil(sa.totalGradeIndex(cumulativeScore: -1, totalScore: 100, gradeScores: [30, 60, 80, 90]), "nil")
        XCTAssertNil(sa.totalGradeIndex(cumulativeScore: 0, totalScore: 100, gradeScores: [30, 60, 80, 90]), "nil")
        XCTAssertNil(sa.totalGradeIndex(cumulativeScore: 10, totalScore: 100, gradeScores: [30, 60, 80, 90]), "nil")
        
        XCTAssertNil(sa.totalGradeIndex(cumulativeScore: 29, totalScore: 100, gradeScores: [30, 60, 80, 90]), "nil")
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 30, totalScore: 100, gradeScores: [30, 60, 80, 90]), 0)
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 31, totalScore: 100, gradeScores: [30, 60, 80, 90]), 0)
        
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 59, totalScore: 100, gradeScores: [30, 60, 80, 90]), 0)
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 60, totalScore: 100, gradeScores: [30, 60, 80, 90]), 1)
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 61, totalScore: 100, gradeScores: [30, 60, 80, 90]), 1)
        
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 79, totalScore: 100, gradeScores: [30, 60, 80, 90]), 1)
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 80, totalScore: 100, gradeScores: [30, 60, 80, 90]), 2)
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 81, totalScore: 100, gradeScores: [30, 60, 80, 90]), 2)
        
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 89, totalScore: 100, gradeScores: [30, 60, 80, 90]), 2)
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 90, totalScore: 100, gradeScores: [30, 60, 80, 90]), 3)
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 91, totalScore: 100, gradeScores: [30, 60, 80, 90]), 3)
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 100, totalScore: 100, gradeScores: [30, 60, 80, 90]), 3)
        XCTAssertEqual(sa.totalGradeIndex(cumulativeScore: 101, totalScore: 100, gradeScores: [30, 60, 80, 90]), 3)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
