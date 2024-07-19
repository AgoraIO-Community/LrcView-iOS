//
//  LineScoreRecorder.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2024/6/3.
//

import Foundation

@objc public class LineScoreRecorder: NSObject {
    var lineScoreDict = [UInt : LineScoreInfo]()
    let logTag = "LineScoreReacorder>>>>"
    
    @objc public func setLyricData(data: LyricModel) {
        lineScoreDict = [UInt : LineScoreInfo]()
        for (offset, element) in data.lines.enumerated() {
            let info = LineScoreInfo(begin: element.beginTime,
                                     duration: element.duration,
                                     score: 0)
            lineScoreDict[UInt(offset)] = info
        }

        Log.info(text: "lineScoreDict count: \(lineScoreDict.count)", tag: logTag)
    }
    
    /// setLineScore
    /// - Parameters:
    ///   - index: the index of line in original lyric file
    ///   - score: the score of line
    /// - Returns: CumulativeScore
    @objc public func setLineScore(index: UInt, score: UInt) -> UInt {
        guard let info = lineScoreDict[index] else {
            Log.errorText(text: "can not find line score info", tag: logTag)
            return calcluateCumulativeScore()
        }
        info.score = score
        Log.info(text: "setLineScore index:(\(index)), score: \(score)", tag: logTag)
        Log.info(text: "\(lineScoreDict.sorted(by:{ $0.key < $1.key}).map({ "i:\($0.key) s:\($0.value.score)" }))", tag: logTag)
        return calcluateCumulativeScore()
    }
    
    /// seek
    /// - Parameter position: current position
    /// - Returns: CumulativeScore
    @objc public func seek(position: UInt) -> UInt {
        Log.info(text: "seek position:\(position)", tag: logTag)
        for index in 0..<lineScoreDict.count {
            let info = lineScoreDict[UInt(index)]!
            if info.begin >= position {
                info.updateScore(score: 0)
                Log.info(text: "reset (\(index)) reset, score: \(info.score)", tag: logTag)
            }
        }
        
        return calcluateCumulativeScore()
    }
    
    private func calcluateCumulativeScore() -> UInt {
        var score: UInt = 0
        for (_, linscore) in lineScoreDict {
            score += linscore.score
        }
        Log.info(text: "calcluateCumulativeScore:\(score)")
        return score
    }
}

extension LineScoreRecorder {
    class LineScoreInfo: CustomStringConvertible {
        let begin: UInt
        let end: UInt
        let duration: UInt
        var score: UInt
        
        init(begin: UInt, duration: UInt, score: UInt) {
            self.begin = begin
            self.end = begin + duration
            self.duration = duration
            self.score = score
        }
        
        func updateScore(score: UInt) {
            self.score = score
        }
        
        var description: String {
            return "score: \(score)"
        }
    }
}
