//
//  FakeScoringMachine.swift
//  Demo
//
//  Created by ZYP on 2024/4/17.
//

import UIKit
import AgoraLyricsScore

class FakeScoringMachine: BaseFakeScoringMachine {
    private var isStart = false
    private var progress: UInt = 0
    private var voicePitchChanger = VoicePitchChanger()
    private var level: Int = 15
    private let scoreRecoder = ScoreRecoder()
    private var currentLineIndex = 0
    
    override func setLyricsModel(lyricModel: LyricModel) {
        super.setLyricsModel(lyricModel: lyricModel)
        scoreRecoder.setLyricsModel(lyricModel: lyricModel)
    }
    
    override func startScore(songId: Int) {
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
    
    override func setProgress(progressInMs: UInt) {
        guard lyricModel != nil else {
            fatalError("model is nil")
        }
        guard isStart else {
            fatalError("isStart == not")
        }
        progress = progressInMs
    }
    
    /// simulate pitch emiiter, actually from rtc engine
    override func pushPitch(pitch: Double) {
        guard isStart else {
            return
        }
        
        guard lyricModel != nil else {
            fatalError("model is nil")
        }
        
        guard let stdPitch = lyricModel.getHitedPitch(progress: progress) else {
            let model = RawScoreDataModel(progressInMs: progress,
                                          speakerPitch: pitch,
                                          pitchScore: 0)
            delegate?.onFakePitch(model: model)
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
        delegate?.onFakePitch(model: model)
        
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
            delegate?.onFakeLineScore(model: cumulativeScoreModel)
            currentLineIndex = index
        }
    }
    
    override func pauseScore() {
        isStart = false
    }
    
    override func resumeScore() {
        isStart = true
    }
    
    override func reset() {
        lyricModel = nil
        isStart = false
        voicePitchChanger.reset()
    }
    
    override func setScoreLevel(level: Int) {
        self.level = level
    }
    
}
