//
//  ScoreRecoder.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2024/4/17.
//

import UIKit
import AgoraLyricsScore

class LineScore {
    var toneScores: [ToneScoreModel]
    var begainTime: Int
    var endTime: Int
    var score: Float
    
    init(toneScores: [ToneScoreModel], begainTime: Int, endTime: Int, score: Float) {
        self.toneScores = toneScores
        self.begainTime = begainTime
        self.endTime = endTime
        self.score = score
    }
    
    func updateScore() {
        score = toneScores.compactMap({ $0.score }).compactMap({ $0 }).reduce(0, +) / Float(toneScores.count)
    }
}

class ScoreRecoder: NSObject {
    private var lineScores = [LineScore]()
    
    func setLyricsModel(lyricModel: LyricModel) {
        lineScores = [LineScore]()
        for line in lyricModel.lines {
            let toneScores = line.tones.map({ ToneScoreModel(tone: $0, score: 0) })
            let lineScore = LineScore(toneScores: toneScores,
                      begainTime: line.beginTime,
                      endTime: line.beginTime + line.duration,
                      score: 0)
            lineScores.append(lineScore)
        }
    }
    
    func appendScore(in progressInMs: Int, score: Float) {
        for lineScore in lineScores {
            if progressInMs >= lineScore.begainTime && progressInMs <= lineScore.endTime {
                for toneScore in lineScore.toneScores {
                    if progressInMs >= toneScore.tone.beginTime && progressInMs <= toneScore.tone.beginTime + toneScore.tone.duration {
                        toneScore.addScore(score: score)
                        lineScore.updateScore()
                        break
                    }
                }
            }
        }
    }
    
    func getLineScore(lineIndex: Int) -> Float {
        return lineScores[lineIndex].score
    }
    
    var cumulativeTotalLinePitchScores: Float {
        lineScores.map({ $0.score }).reduce(0, +)
    }
}

/// 字得分
public class ToneScoreModel: NSObject {
    @objc public let tone: LyricToneModel
    /// 0-100
    @objc public var score: Float
    var scores = [Float]()
    
    @objc public init(tone: LyricToneModel,
                      score: Float) {
        self.tone = tone
        self.score = score
    }
    
    func addScore(score: Float) {
        scores.append(score)
        self.score = scores.reduce(0, +) / Float(scores.count)
    }
}
