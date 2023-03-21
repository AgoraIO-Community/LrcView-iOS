//
//  TestProgressChecker.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/3/21.
//

import XCTest
@testable import AgoraLyricsScore

class TestProgressChecker: XCTestCase, ProgressCheckerDelegate {
    let checker = ProgressChecker()
    let exp0 = XCTestExpectation(description: "test checker 0")
    let exp1 = XCTestExpectation(description: "test checker 1")
    let exp2 = XCTestExpectation(description: "test checker 2")
    let exp3 = XCTestExpectation(description: "test checker 3")
    let exp4 = XCTestExpectation(description: "test checker 4")
    var testIndex = 0
    
    override func setUpWithError() throws {
        checker.delegate = self
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample0() throws {
        testIndex = 0
        checker.set(progress: 0)
        checker.set(progress: 1)
        checker.set(progress: 5)
        
        wait(for: [exp0], timeout: 2)
    }
    
    func testExample1() throws {
        testIndex = 1
        checker.delegate = self
        checker.set(progress: 6)
        
        wait(for: [exp1], timeout: 2)
    }
    
    func testExample2() throws {
        testIndex = 2
        checker.set(progress: 0)
        checker.set(progress: 1)
        checker.set(progress: 5)
        checker.reset()
        checker.set(progress: 6)
        wait(for: [exp2], timeout: 2)
    }
    
    func testExample3() throws {
        testIndex = 3
        checker.set(progress: 0)
        checker.set(progress: 1)
        checker.set(progress: 5)
        checker.reset()
        checker.set(progress: 6)
        checker.reset()
        checker.set(progress: 6)
        wait(for: [exp3], timeout: 2)
    }
    
    func testExample4() throws {
        testIndex = 4
        checker.set(progress: 0)
        checker.set(progress: 1)
        checker.set(progress: 5)
        checker.reset()
        checker.set(progress: 6)
        checker.reset()
        checker.set(progress: 6)
        checker.reset()
        checker.set(progress: 6)
        
        wait(for: [exp4], timeout: 2)
    }
    
    
    func progressCheckerDidProgressPause() {
        switch testIndex {
        case 0:
            exp0.fulfill()
            return
        case 1:
            exp1.fulfill()
        case 2:
            exp2.fulfill()
        case 3:
            exp3.fulfill()
        case 4:
            exp4.fulfill()
        default:
            break
        }
    }
}
