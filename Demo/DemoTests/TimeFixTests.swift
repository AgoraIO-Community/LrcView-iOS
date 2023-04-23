//
//  TimeFixTests.swift
//  DemoTests
//
//  Created by ZYP on 2023/4/25.
//

import XCTest
import AgoraRtcKit
import AgoraLyricsScore

class TimeFixTests: XCTestCase {
    let lines: [TimeFix.Line] = [.init(beginTime: 1000,
                                       duration: 1000),
                                 .init(beginTime: 2500,
                                       duration: 1000),
                                 .init(beginTime: 4000,
                                       duration: 1000),
                                 .init(beginTime: 5500,
                                       duration: 1000),
                                 .init(beginTime: 7000,
                                       duration: 1000)]
    
    func test1() throws {
        let result = TimeFix.handleFixTime(startTime: 0, endTime: 0, lines: [])
        XCTAssertNil(result)
    }

    func test2() throws {
        XCTAssertNil(TimeFix.handleFixTime(startTime: 0, endTime: 0, lines: lines))
        XCTAssertNil(TimeFix.handleFixTime(startTime: 1, endTime: 2, lines: lines))
        XCTAssertNil(TimeFix.handleFixTime(startTime: 1, endTime: 999, lines: lines))
    }
    
    func test3() throws {
        XCTAssertNil(TimeFix.handleFixTime(startTime: 8001, endTime: 9000, lines: lines))
        XCTAssertNil(TimeFix.handleFixTime(startTime: 9000, endTime: 10000, lines: lines))
    }
    
    func test4() throws {
        let result = TimeFix.handleFixTime(startTime: 500, endTime: 1001, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 1000)
        XCTAssertTrue(result!.1 == 2000)
    }
    
    func test6() throws {
        let result = TimeFix.handleFixTime(startTime: 1000, endTime: 1001, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 1000)
        XCTAssertTrue(result!.1 == 2000)
    }
    
    func test7() throws {
        let result = TimeFix.handleFixTime(startTime: 2000, endTime: 2350, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 1000)
        XCTAssertTrue(result!.1 == 3500)
    }
    
    func test8() throws {
        let result = TimeFix.handleFixTime(startTime: 2001, endTime: 2350, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 2500)
        XCTAssertTrue(result!.1 == 3500)
    }
    
    func test9() throws {
        let result = TimeFix.handleFixTime(startTime: 2001, endTime: 2500, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 2500)
        XCTAssertTrue(result!.1 == 3500)
    }
    
    func test10() throws {
        let result = TimeFix.handleFixTime(startTime: 2500, endTime: 2501, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 2500)
        XCTAssertTrue(result!.1 == 3500)
    }
    
    func test11() throws {
        let result = TimeFix.handleFixTime(startTime: 2500, endTime: 3500, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 2500)
        XCTAssertTrue(result!.1 == 3500)
    }
    
    func test12() throws {
        let result = TimeFix.handleFixTime(startTime: 2501, endTime: 3500, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 2500)
        XCTAssertTrue(result!.1 == 3500)
    }
    
    func test13() throws {
        let result = TimeFix.handleFixTime(startTime: 2501, endTime: 3501, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 2500)
        XCTAssertTrue(result!.1 == 5000)
    }
    
    func test14() throws {
        let result = TimeFix.handleFixTime(startTime: 1, endTime: 8001, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 1000)
        XCTAssertTrue(result!.1 == 8000)
    }
    
    func test15() throws {
        let result = TimeFix.handleFixTime(startTime: 1001, endTime: 8001, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 1000)
        XCTAssertTrue(result!.1 == 8000)
    }
    
    func test16() throws {
        let result = TimeFix.handleFixTime(startTime: 1, endTime: 8000, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 1000)
        XCTAssertTrue(result!.1 == 8000)
    }
    
    func test17() throws {
        let result = TimeFix.handleFixTime(startTime: 1001, endTime: 7999, lines: lines)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.0 == 1000)
        XCTAssertTrue(result!.1 == 8000)
    }
}

class TimeFixTestsGPT: XCTestCase {
    var lines: [TimeFix.Line]!

    override func setUp() {
        super.setUp()
        
        // 设置测试数据
        lines = [TimeFix.Line(beginTime: 0, duration: 2),
                 TimeFix.Line(beginTime: 3, duration: 3),
                 TimeFix.Line(beginTime: 7, duration: 2)]
    }

    override func tearDown() {
        lines = nil
        super.tearDown()
    }

    // 测试所有行为空的情况
    func testHandleFixTimeWithEmptyLines() {
        let result = TimeFix.handleFixTime(startTime: 0, endTime: 10, lines: [])
        XCTAssertNil(result, "处理时间失败")
    }

    // 测试开始时间比第一行早，结束时间也比第一行早的情况
    func testHandleFixTimeWithStartBeforeFirstLine() {
        let result = TimeFix.handleFixTime(startTime: -1, endTime: 1, lines: lines)
        XCTAssertEqual(result?.0, 0, "开始时间不正确")
        XCTAssertEqual(result?.1, 2, "结束时间不正确")
    }

    // 测试开始时间和结束时间都比最后一行晚的情况
    func testHandleFixTimeWithEndAfterLastLine() {
        let result = TimeFix.handleFixTime(startTime: 10, endTime: 12, lines: lines)
        XCTAssertNil(result, "处理时间失败")
    }

    // 测试开始时间比第一行早，但结束时间在第一行内的情况
    func testHandleFixTimeWithStartBeforeFirstLineAndEndInFirstLine() {
        let result = TimeFix.handleFixTime(startTime: 1, endTime: 4, lines: lines)
        XCTAssertEqual(result?.0, 0, "开始时间不正确")
        XCTAssertEqual(result?.1, 6, "结束时间不正确")
    }

    // 测试开始时间在第一行外，结束时间比最后一行晚的情况
    func testHandleFixTimeWithStartAfterFirstLineAndEndAfterLastLine() {
        let result = TimeFix.handleFixTime(startTime: 5, endTime: 13, lines: lines)
        XCTAssertEqual(result?.0, 3, "开始时间不正确")
        XCTAssertEqual(result?.1, 9, "结束时间不正确")
    }

    // 测试开始时间和结束时间都在第二行内的情况
    func testHandleFixTimeWithStartInSecondLineAndEndInSecondLine() {
        let result = TimeFix.handleFixTime(startTime: 4, endTime: 6, lines: lines)
        XCTAssertEqual(result?.0, 3, "开始时间不正确")
        XCTAssertEqual(result?.1, 6, "结束时间不正确")
    }

    // 测试开始时间在第二行之间，结束时间在第三行外的情况
    func testHandleFixTimeWithStartBetweenSecondAndThirdLineAndEndAfterLastLine() {
        let result = TimeFix.handleFixTime(startTime: 5, endTime: 10, lines: lines)
        XCTAssertEqual(result?.0, 3, "开始时间不正确")
        XCTAssertEqual(result?.1, 9, "结束时间不正确")
    }
}
