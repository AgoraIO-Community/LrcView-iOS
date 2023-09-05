//
//  ScoreClaculatorTest.swift
//  DemoTests
//
//  Created by ZYP on 2023/9/2.
//

import XCTest
import AgoraLyricsScore

final class ScoreClaculatorTest: XCTestCase {
    
    func test1() {
        calculate(refPitchName: "", userPitchName: "")
    }
    
    func calculate(refPitchName: String, userPitchName: String) {
        let refPitchUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "反方向的钟-原唱干声.pitch", ofType: nil)!)
        let refPitchData = try! Data(contentsOf: refPitchUrl)
        let refModel = KaraokeView.parsePitchData(data: refPitchData)!
        let refPitchs = refModel.items.map({ Float($0.value) })
        
        let fileUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "x", ofType: "txt")!)
        let fileData = try! Data(contentsOf: fileUrl)
        let pitchFileString = String(data: fileData, encoding: .utf8)!
        let userPitchs = parse(pitchFileString: pitchFileString).map({ Float($0) })
        
        let refPitchLen = refPitchs.count
        let refPitchInterval = Float(refModel.timeInterval)
        let userPitchLen = userPitchs.count
        let userPitchInterval: Float = 50
        
        
        let config = ScoreClaculator.Config(refPitchLen: refPitchLen,
                                            refPitchInterval: refPitchInterval,
                                            userPitchLen: userPitchLen,
                                            userPitchInterval: userPitchInterval)
        
        let score = ScoreClaculator.calculate(config: config,
                                              refPitchs: refPitchs,
                                              userPitchs: userPitchs)
        
        if let s = score {
            let radio = Int(config.userPitchInterval / config.refPitchInterval)
            let all = (refPitchs.filter({ $0 > 0 }).count * 100) / radio
            let finaleScore = (Float(s) / Float(all)) * 100
            KaraokeView.log(text: "finaleScore:\(finaleScore) = score:\(s) / all: \(all) all count: \(all * radio / 100)")
        }
        else {
            print("no score")
        }
    }
    
    private func parse(pitchFileString: String) -> [Double] {
        if pitchFileString.contains("\r\n") {
            let array = pitchFileString.split(separator: "\r\n").map({ Double($0)! })
            return array
        }
        else {
            let array = pitchFileString.split(separator: "\n").map({ Double($0)! })
            return array
        }
    }
}
