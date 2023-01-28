//
//  ScoringVM+Handle+ScoreAlgorithm.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/28.
//

import Foundation

extension ScoringVM {
    func setupGradeData() -> [GradeItem] {
        let count = scoreAlgorithm.totalGradeCount()
        var temp = [GradeItem]()
        for i in 0...count {
            let score = scoreAlgorithm.totalGradeScoreByIndex(gradeIndex: i)
            guard score > 0, score < 100 else {
                fatalError("totalGradeScoreByIndex: out bounds")
            }
            let description = scoreAlgorithm.totalGradeDescription(gradeIndex: i)
            let image = scoreAlgorithm.totalGradeImage(gradeIndex: i)
            let item = GradeItem(score: score,
                                 description: description,
                                 image: image)
            temp.append(item)
        }
        return temp
    }
    
    func getGradeImage() -> UIImage? {
        guard let index = scoreAlgorithm.totalGradeIndex(cumulativeScore: cumulativeScore,
                                                         totalScore: totalScore,
                                                         gradeScores: gradeItems.map({ $0.score })) else {
            return nil
        }
        return gradeItems[index].image
    }
}


