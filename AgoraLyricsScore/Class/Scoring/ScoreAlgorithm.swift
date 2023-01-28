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
        return 4
    }
    
    func totalGradeScoreByIndex(gradeIndex: Int) -> Int {
        switch gradeIndex {
        case 0:
            return 30
        case 1:
            return 60
        case 2:
            return 80
        default:
            return 90
        }
    }
    
    func totalGradeDescription(gradeIndex: Int) -> String {
        switch gradeIndex {
        case 0:
            return "C"
        case 1:
            return "B"
        case 2:
            return "A"
        default:
            return "S"
        }
    }
    
    func totalGradeImage(gradeIndex: Int) -> UIImage {
        switch gradeIndex {
        case 0:
            return Bundle.currentBundle.image(name: "icon-C")!
        case 1:
            return Bundle.currentBundle.image(name: "icon-B")!
        case 2:
            return Bundle.currentBundle.image(name: "icon-A")!
        default:
            return Bundle.currentBundle.image(name: "icon-S")!
        }
    }
}
