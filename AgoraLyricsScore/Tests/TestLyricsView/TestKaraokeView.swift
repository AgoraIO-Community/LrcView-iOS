//
//  TestKaraokeView.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/9/26.
//

import XCTest
@testable import AgoraLyricsScore

final class TestKaraokeView: XCTestCase, KaraokeDelegate {
    var karaokeView: KaraokeView!
    let exp = XCTestExpectation(description: "test TestKaraokeView")

    func testExample() throws { /** 重现#CSD-59221、#CSD-60022 **/
        karaokeView = KaraokeView(frame: .init(x: 0, y: 0, width: 350, height: 400),loggers:[ConsoleLogger()])
        let url = URL(fileURLWithPath: Bundle.current.path(forResource: "testissue60022", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        guard let model = KaraokeView.parseLyricData(lyricFileData: data) else {
            XCTFail()
            return
        }
        karaokeView.delegate = self
        karaokeView.setLyricData(data: model, usingInternalScoring: true)
        for time: UInt in 0...1001000 {
            karaokeView.setProgress(progress: time)
        }
        sleep(1)
        karaokeView.reset()
        wait(for: [exp], timeout: 60 * 3)
    }
    
    func onKaraokeView(view: KaraokeView, didFinishLineWith model: LyricLineModel, score: Int, cumulativeScore: Int, lineIndex: Int, lineCount: Int) {
        exp.fulfill()
    }
    
}
