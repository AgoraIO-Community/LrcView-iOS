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
        XCTAssertTrue(model.sourceType == .lrc)
    }
    
    func testLrcFileWithPitchFile() { /** lrc and pitchFile **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "6246262727282260", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        let pitchFileUrl = URL(fileURLWithPath: Bundle.current.path(forResource: "6246262727282260", ofType: "bin")!)
        let pitchFileData = try! Data(contentsOf: pitchFileUrl)
        guard let model = KaraokeView.parseLyricData(data: data, pitchFileData: pitchFileData) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.tones.count > 0)
        XCTAssertEqual(model.hasPitch, true)
        XCTAssertTrue(model.sourceType == .lrc)
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
        XCTAssert(model.duration  == 186022)
        XCTAssert(model.preludeEndPosition  == 18487)
        XCTAssertTrue(model.hasPitch)
        XCTAssertTrue(model.sourceType == .xml)
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
    
    func testEnhancedLrcFile() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "EnhancedLRCformat", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(data: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 26)
        XCTAssert(model.lines.first!.content == "又是九月九重阳夜难聚首")
        XCTAssertTrue(model.lines[0].tones[0].beginTime == 23 * 1000 + 997)
        XCTAssert(model.lines[0].tones[10].duration == (29 * 1000 + 326) - (28 * 1000 + 665) - 1) /** gap was 1 ms between lines **/
        XCTAssertEqual(model.hasPitch, false)
        XCTAssertTrue(model.sourceType == .lrc)
    }
    
    func testEnhancedLrcFileWithPitchFile() { /** Enhanced lrc and pitchFile **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "EnhancedLRCformat", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        let pitchFileUrl = URL(fileURLWithPath: Bundle.current.path(forResource: "EnhancedLRCformat", ofType: "pitch")!)
        let pitchFileData = try! Data(contentsOf: pitchFileUrl)
        guard let model = KaraokeView.parseLyricData(data: data, pitchFileData: pitchFileData) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 26)
        XCTAssert(model.lines.first!.tones.count > 0)
        XCTAssertEqual(model.hasPitch, true)
        XCTAssertTrue(model.sourceType == .lrc)
        XCTAssertTrue(model.lines[0].tones[0].beginTime == 23 * 1000 + 997)
        XCTAssert(model.lines[0].tones[10].duration == (29 * 1000 + 326) - (28 * 1000 + 665) - 1) /** gap was 1 ms between lines **/
        XCTAssertTrue(model.lines.last!.duration > 0)
        XCTAssertTrue(model.lines.last!.tones.last!.duration > 0)
        XCTAssertTrue(model.sourceType == .lrc)
    }
    
    func testPerformancePitchParser() throws {
        let path = Bundle.current.path(forResource: "pitch", ofType: "bin")!
        let fileUrl = URL(fileURLWithPath: path)
        let fileData = try! Data(contentsOf: fileUrl)
        let parser = PitchParser()
        self.measure {
            let _ = parser.parse(data: fileData)
        }
    }
    
    func testPerfromanceParseLyricData() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "6246262727282260", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        let pitchFileUrl = URL(fileURLWithPath: Bundle.current.path(forResource: "6246262727282260", ofType: "bin")!)
        let pitchFileData = try! Data(contentsOf: pitchFileUrl)
        self.measure {
            let _ = KaraokeView.parseLyricData(data: data, pitchFileData: pitchFileData)
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
