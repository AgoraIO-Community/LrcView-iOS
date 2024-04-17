//
//  FakeScoringMachine.swift
//  Demo
//
//  Created by ZYP on 2024/4/17.
//

import UIKit
import AgoraLyricsScore

struct RawScoreDataModel {
    let progressInMs: Int
    let speakerPitch: Double
    let pitchScore: Float
}

struct CumulativeScoreDataModel {
    let progressInMs: Int
    /// 已经演唱过的最近一个歌曲的行数
    let performedLineIndex: Int
    /// 已经演唱过的歌曲行数
    let performedTotalLines: Int
    /// 已经演唱过的歌曲中所有行数的累积总得分
    let cumulativeTotalLinePitchScores: Float
    /// 对已经演唱过的行数做计算，而得出来的音高得分
    let energyScore: Float
    let performedLineScore: Float
}

protocol FakeScoringMachineDelegate: NSObjectProtocol {
    func fakeScoringMachine(onAllRefPitchs model: LyricModel)
    func fakeScoringMachine(onLineScore model: CumulativeScoreDataModel)
    func fakeScoringMachine(onPitch model: RawScoreDataModel)
}

class FakeScoringMachine: NSObject {
    weak var delegate: FakeScoringMachineDelegate?
    private var isStart = false
    private var isPause = false
    private var progress = 0
    private var lyricModel: LyricModel!
    private var voicePitchChanger = VoicePitchChanger()
    private var level: Int = 15
    private let scoreRecoder = ScoreRecoder()
    private var currentLineIndex = 0
    
    func setLyricsModel(lyricModel: LyricModel) {
        self.lyricModel = lyricModel
        scoreRecoder.setLyricsModel(lyricModel: lyricModel)
        delegate?.fakeScoringMachine(onAllRefPitchs: lyricModel)
    }
    
    func startScore() {
        guard lyricModel != nil else {
            fatalError("model is nil")
        }
        guard !isStart else {
            fatalError("isStart == not")
        }
        isStart = true
        currentLineIndex = 0
        voicePitchChanger.reset()
    }
    
    func setProgress(progressInMs: Int) {
        guard lyricModel != nil else {
            fatalError("model is nil")
        }
        guard isStart else {
            fatalError("isStart == not")
        }
        progress = progressInMs
    }
    
    /// simulate pitch emiiter, actually from rtc engine
    func pushPitch(pitch: Double) {
        guard isStart else {
            return
        }
        
        guard lyricModel != nil else {
            fatalError("model is nil")
        }
        
        guard let stdPitch = lyricModel.getHitedPitch(progress: progress) else {
            return
        }
        
        let pitchAfterHandle = voicePitchChanger.handlePitch(stdPitch: stdPitch,
                                                             voicePitch: pitch,
                                                             stdMaxPitch: lyricModel.maxPitch)
        let score = ToneCalculator.calculedScore(voicePitch: pitchAfterHandle,
                                                 stdPitch: stdPitch,
                                                 scoreLevel: level,
                                                 scoreCompensationOffset: 0)
        scoreRecoder.appendScore(in: progress, score: score)
        let model = RawScoreDataModel(progressInMs: progress,
                                      speakerPitch: pitchAfterHandle,
                                      pitchScore: score)
        delegate?.fakeScoringMachine(onPitch: model)
        
        if let index = lyricModel.findCurrentIndexOfLine(progress: progress),
           currentLineIndex != index { /** gen next line **/
            let lineScore = scoreRecoder.getLineScore(lineIndex: currentLineIndex)
            let cumulativeTotalLinePitchScores = scoreRecoder.cumulativeTotalLinePitchScores
            let cumulativeScoreModel = CumulativeScoreDataModel(progressInMs: progress,
                                                                performedLineIndex: currentLineIndex,
                                                                performedTotalLines: lyricModel.lines.count - (currentLineIndex + 1),
                                                                cumulativeTotalLinePitchScores: cumulativeTotalLinePitchScores,
                                                                energyScore: 0,
                                                                performedLineScore: lineScore)
            delegate?.fakeScoringMachine(onLineScore: cumulativeScoreModel)
            currentLineIndex = index
        }
    }
    
    func pauseScore() {
        isStart = false
    }
    
    func resumeScore() {
        isStart = true
    }
    
    func setScoreLevel(level: Int) {
        self.level = level
    }
    
}

extension LyricModel {
    var minPitch: Double {
        let pitchs = lines.flatMap({ $0.tones.filter({ $0.word != " " }).map({ $0.pitch }) })
        let minValue = pitchs.min() ?? 0
        return minValue
    }
    
    var maxPitch: Double {
        let pitchs = lines.flatMap({ $0.tones.filter({ $0.word != " " }).map({ $0.pitch }) })
        let maxValue = pitchs.max() ?? 0
        return maxValue
    }
    
    func getHitedPitch(progress: Int) -> Double? {
        let pitchBeginTime = progress
        for line in lines {
            if pitchBeginTime >= line.beginTime && pitchBeginTime <= line.beginTime + line.duration {
                for tone in line.tones {
                    if pitchBeginTime >= tone.beginTime && pitchBeginTime <= tone.beginTime + tone.duration {
                        return tone.pitch
                    }
                }
            }
        }
        return nil
    }
    
    func findCurrentIndexOfLine(progress: Int) -> Int? {
        let lineEndTimes = lines.map({ $0.beginTime + $0.duration })
        
        if progress > lineEndTimes.last! {
            return lineEndTimes.count
        }
        
        if progress <= lineEndTimes.first! {
            return 0
        }
        
        var lastEnd = 0
        for (offset, value) in lineEndTimes.enumerated() {
            if progress > lastEnd, progress <= value  {
                return offset
            }
            lastEnd = value
        }
        return nil
    }
}
