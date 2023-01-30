//
//  ScoreAlgorithm.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

class ScoreAlgorithm: IScoreAlgorithm {
    func getLineScore(with toneScores: [ToneScoreModel]) -> Int {
        if toneScores.isEmpty { return 0 }
        return toneScores.map({ $0.score }).reduce(0, +) / toneScores.count
    }
}
