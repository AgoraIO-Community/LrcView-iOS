//
//  ScoreAlgorithm.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

class ScoreAlgorithm: IScoreAlgorithm {
    func getLineScore(with toneScores: [ToneScoreModel]) -> Int {
        return 0
    }
    
    func incentiveGradeCount() -> Int {
        return 0
    }
    
    func incentiveGradeIndex(score: Int) -> Int {
        return 0
    }
    
    func incentiveGradeDescription(gradeIndex: Int) -> String {
        return ""
    }
    
    func incentiveCombinable(gradeIndex: Int) -> Bool {
        return false
    }
    
    func totalGradeCount() -> Int {
        return 3
    }
    
    func totalGradeIndex(score: Int) -> Int {
        return 2
    }
    
    func totalGradeDescription(gradeIndex: Int) -> String {
        return ""
    }
}
