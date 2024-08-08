//
//  TestBoard.swift
//  AgoraMeetingCore-Unit-Tests
//
//  Created by ZYP on 2021/6/29.
//

import XCTest
@testable import AgoraLyricsScore

class TestParser: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLrcFile() throws { /** lrc normal **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "lrc", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.content.contains("什么是幸福"))
    }
    
    func testLrcFile2() throws { /** lrc normal **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "CJhd625070", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.content.contains("他想知道那是谁"))
    }
    
    func testXMLFile() throws { /** xml normal **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "745012", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.beginTime == 18487)
        XCTAssert(model.name  == "十年 ")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.lyricsType  == .xml)
        XCTAssert(model.duration  == 186022)
        XCTAssert(model.preludeEndPosition  == 18487)
        XCTAssertTrue(model.hasPitch)
    }
    
    func testEmptyData() { /** EmptyData **/
        let data = Data()
        let model = KaraokeView.parseLyricData(lyricFileData: data)
        XCTAssertNil(model)
    }
    
    func testSubData() { /** SubData **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "lrc", ofType: "lrc")!)
        var data = try! Data(contentsOf: url)
        data = data.subdata(in: 90...100)
        let model = KaraokeView.parseLyricData(lyricFileData: data)
        XCTAssertNil(model)
    }
    
    func testTimeIssue1() { /** xml 异常 时间严重异常 **/
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "CJ1420023417", ofType: "xml")!)
        let data = try! Data(contentsOf: url)

        let parser = Parser()
        let model = parser.parseLyricData(data: data, lyricOffset: 0)
        XCTAssertNil(model)
    }
    
    func testTimeIssue2() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "745012-timeissue2", ofType: "xml")!)
        let data = try! Data(contentsOf: url)

        let parser = Parser()
        let model = parser.parseLyricData(data: data, lyricOffset: 0)
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
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.beginTime == 28970)
    }
    
    func testNoWordInTone() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "noWordInTone", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines[0].tones[0].beginTime == 34129)
        XCTAssert(model.lines[0].tones[1].word  == "")
        XCTAssert(model.lines[0].tones[2].word  == "响")
    }
    
    func testKRCFile() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133", ofType: "krc")!)
        let data = try! Data(contentsOf: url)
        let p = KRCParser()
        guard let model = p.parse(krcFileData: data, lyricOffset: 10) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 44)
        XCTAssert(model.lines.first!.beginTime == 1067 + 10)
        XCTAssert(model.name  == "十年")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.lyricsType  == .krc)
        XCTAssertEqual(model.duration, 381601 + 10)
        XCTAssert(model.preludeEndPosition  == 0)
        XCTAssertTrue(model.hasPitch == false)
    }
    
    func testKRCFile2() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "3017502026609527683", ofType: "krc")!)
        let data = try! Data(contentsOf: url)
        let p = KRCParser()
        guard let model = p.parse(krcFileData: data, lyricOffset: 0) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 62)
        XCTAssert(model.lines.first!.beginTime == 0)
        XCTAssert(model.name  == "在你的身边")
        XCTAssert(model.singer  == "盛哲")
        XCTAssert(model.lyricsType  == .krc)
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
        guard let model = p.parseLyricData(data: krcFileData, pitchFileData: pitchFileData, lyricOffset: 0, includeCopyrightSentence: true) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count > 0)
        XCTAssert(model.lines.first!.beginTime == 1067)
        XCTAssert(model.name  == "十年")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.lyricsType  == .krc)
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
        let model = KaraokeView.parseLyricData(lyricFileData: data, pitchFileData: data)
        XCTAssertNil(model)
    }
    
    func testKrcEmptyPitchData() { /** EmptyPitchData **/
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133", ofType: "krc")!))
        
        guard let model = KaraokeView.parseLyricData(lyricFileData: krcFileData) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 44)
        XCTAssert(model.lines.first!.beginTime == 1067)
        XCTAssert(model.name  == "十年")
        XCTAssert(model.singer  == "陈奕迅")
        XCTAssert(model.lyricsType  == .krc)
        XCTAssertEqual(model.duration, 381601)
        XCTAssert(model.preludeEndPosition  == 0)
        XCTAssertTrue(model.hasPitch == false)
    }
    
    func testLryType() {
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "8141335308133421388", ofType: "krc")!))
        
        guard let model = KaraokeView.parseLyricData(lyricFileData: krcFileData) else {
            XCTFail()
            return
        }
        
        XCTAssert(model.lyricsType  == .krc)
        XCTAssert(model.lines.count == 86)
        XCTAssert(model.name  == "热烈的少年 (是热烈)")
        XCTAssert(model.lines[1].beginTime == 737)
    }
    
    func testEnhancedLrcFile() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "EnhancedLRCformat", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 26)
        XCTAssert(model.lines.first!.content == "又是九月九重阳夜难聚首")
        XCTAssertTrue(model.lines[0].tones[0].beginTime == 23 * 1000 + 997)
        XCTAssert(model.lines[0].tones[10].duration == (29 * 1000 + 326) - (28 * 1000 + 665) - 1) /** gap was 1 ms between lines **/
        XCTAssertEqual(model.hasPitch, false)
        XCTAssertTrue(model.lyricsType == .lrc)
    }
    
    func testEnhancedLrcFile2() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "EnhancedLRCformat2", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 52)
        XCTAssert(model.lines.first!.content == "apologiz")
        XCTAssertTrue(model.lines[0].tones[0].beginTime == 4 * 1000 + 841)
        XCTAssert(model.lines[7].tones[12].duration == (54 * 1000 + 578) - (54 * 1000 + 56) - 1) /** gap was 1 ms between lines **/
        XCTAssertEqual(model.hasPitch, false)
        XCTAssertTrue(model.lyricsType == .lrc)
    }
    
    func testEnhancedLrcFile3() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "EnhancedLRCformat3", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 8)
        XCTAssert(model.lines.first!.content == "他们总是说我有时不会怎么讲话")
        XCTAssertTrue(model.lines[0].tones[0].beginTime == 18 * 1000 + 912)
        /// <04:51.526>大[04:53.964]
        XCTAssert(model.lines[6].tones[11].duration == (4 * 60 * 1000 + 53 * 1000 + 964) - (4 * 60 * 1000 + 51 * 1000 + 526) - 1) /** gap was 1 ms between lines **/
        XCTAssertEqual(model.hasPitch, false)
        XCTAssertTrue(model.lyricsType == .lrc)
    }
    
    func testEnhancedLrcFile4() {
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "EnhancedLRCformat4", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        XCTAssert(model.lines.count == 52)
        XCTAssert(model.lines.first!.content == "apologiz")
        XCTAssertTrue(model.lines[0].tones[0].beginTime == 4 * 1000 + 841)
        XCTAssert(model.lines[7].tones[12].duration == (54 * 1000 + 578) - (54 * 1000 + 56) - 1) /** gap was 1 ms between lines **/
        XCTAssertEqual(model.hasPitch, false)
        XCTAssertTrue(model.lyricsType == .lrc)
    }
    
    func testIncludeCopyrightSentence1() {
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133", ofType: "krc")!))
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        let model = KaraokeView.parseLyricData(lyricFileData: krcFileData,
                                               pitchFileData: pitchFileData,
                                               includeCopyrightSentence: false)
        XCTAssertNotNil(model)
        XCTAssert(model!.lyricsType  == .krc)
        XCTAssertEqual(model!.lines.count, 40)
        XCTAssertEqual(model!.lines.first!.content, "如果那两个字没有颤抖")
        XCTAssertEqual(model!.copyrightSentenceLineCount, 4)
    }
    
    func testIncludeCopyrightSentence2() {
        var krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "3017502026609527683", ofType: "krc")!))
        var pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "3017502026609527683.pitch", ofType: nil)!))
        var model = KaraokeView.parseLyricData(lyricFileData: krcFileData,
                                               pitchFileData: pitchFileData,
                                               includeCopyrightSentence: false)
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.lines.count ?? 0, 50)
        XCTAssertEqual(model!.lines.first!.content, "安静地又说分开")
        XCTAssertEqual(model?.copyrightSentenceLineCount ?? 0, 12)
        
        krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "5803512921786982975", ofType: "krc")!))
        pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "5803512921786982975.pitch", ofType: nil)!))
        model = KaraokeView.parseLyricData(lyricFileData: krcFileData,
                                           pitchFileData: pitchFileData,
                                           includeCopyrightSentence: false)
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.lines.count ?? 0, 58)
        XCTAssertEqual(model!.lines.first!.content, "不知道")
        XCTAssertEqual(model?.copyrightSentenceLineCount ?? 0, 7)
    }
}
