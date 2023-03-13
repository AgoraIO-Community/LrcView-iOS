//
//  TestBoard.swift
//  AgoraMeetingCore-Unit-Tests
//
//  Created by ZYP on 2021/6/29.
//

import XCTest
@testable import AgoraLyricsScore

class TestParser: XCTestCase {
    func testLrcFile() throws { /** lrc normal **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "lrc", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.content.contains("什么是幸福 "))
        XCTAssertEqual(model.hasPitch, false)
        
        // MARK: - TODO has pitchfile
        
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
        XCTAssertTrue(model.isTimeAccurateToWord)
        
        // MARK: - TODO has pitchfile
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
        let model = parser.parseLyricData(data: data, pitchFileData: nil)
        XCTAssertNil(model)
    }
    
    func testTimeIssue2() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "745012-timeissue2", ofType: "xml")!)
        let data = try! Data(contentsOf: url)

        let parser = Parser()
        let model = parser.parseLyricData(data: data, pitchFileData: nil)
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
    
    func testPitchFile() {
        let path = Bundle.current.path(forResource: "pitch", ofType: "bin")!
        let fileUrl = URL(fileURLWithPath: path)
        let fileData = try! Data(contentsOf: fileUrl)
        
        let parser = PitchParser()
        let model = parser.parse(data: fileData)
        XCTAssertNotNil(model)
        XCTAssertEqual(model!.timeInterval, 10)
        XCTAssertEqual(model!.version, 1)
        XCTAssertEqual(model!.reserved, 0)
        
        /// 预期结果
        let path2 = Bundle.current.path(forResource: "pitch", ofType: "txt")!
        let fileUrl2 = URL(fileURLWithPath: path2)
        let fileData2 = try! Data(contentsOf: fileUrl2)
        let model2 = parse(data: fileData2)
        
        for item in model!.items.enumerated() {
            XCTAssertEqual(model2!.items[item.offset].value, model!.items[item.offset].value.keep3)
        }
    }
    
    /// parse
    /// - Parameters:
    ///   - data: data of pitch file
    ///   - durationPerValue: ms
    func parse(data: Data, durationPerValue: Int = 10) -> PitchModel? {
        guard let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        let values = string.split(separator: "\n").map({ Double($0)! })
        let duration = values.count * durationPerValue
        let items = values.enumerated().map({ PitchItem(value: $0.1, beginTime: $0.0 * durationPerValue, duration: durationPerValue) })
        let model = PitchModel(version: 0,
                               timeInterval: 0,
                               reserved: 0,
                               duration: duration,
                               items: items)
        return model
    }
}

extension Double {
    var keep3: Double {
        (self * 1000).rounded() / 1000
    }
}
