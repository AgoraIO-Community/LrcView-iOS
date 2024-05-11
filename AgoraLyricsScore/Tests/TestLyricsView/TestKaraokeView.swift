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
        let krcFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.krc", ofType: nil)!))
        let pitchFileData = try! Data(contentsOf: URL(fileURLWithPath: Bundle.current.path(forResource: "4875936889260991133.pitch", ofType: nil)!))
        
        guard let model = KaraokeView.parseLyricData(krcFileData: krcFileData,
                                                     pitchFileData: pitchFileData) else {
            XCTFail()
            return
        }
        guard let model = KaraokeView.parseLyricData(krcFileData: krcFileData, pitchFileData: pitchFileData) else {
            XCTFail()
            return
        }
        karaokeView.delegate = self
        karaokeView.setLyricData(data: model)
        for time in 0...1001000 {
            karaokeView.setProgress(progressInMs: UInt(time))
        }
        sleep(1)
        karaokeView.reset()
//        wait(for: [exp], timeout: 60 * 3)
    }
    
}
