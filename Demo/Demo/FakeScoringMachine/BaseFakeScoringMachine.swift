//
//  BaseScoringMachine.swift
//  Demo
//
//  Created by ZYP on 2024/4/18.
//

import AgoraLyricsScore

struct RawScoreDataModel {
    let progressInMs: UInt
    let speakerPitch: Double
    let pitchScore: Float
}

struct CumulativeScoreDataModel {
    let progressInMs: UInt
    /// 已经演唱过的最近一个歌曲的行数
    let performedLineIndex: Int
    /// 已经演唱过的歌曲行数
    let performedTotalLines: Int
    /// 已经演唱过的歌曲中所有行数的累积总得分
    let cumulativeTotalLinePitchScores: Float
    /// 对已经演唱过的行数做计算，而得出来的音高得分
    let energyScore: Float
    /// 当前行分数
    let performedLineScore: Float
}

protocol FakeScoringMachineDelegate: NSObjectProtocol {
    func onFakeAllRefPitchs(model: LyricModel)
    func onFakeLineScore(model: CumulativeScoreDataModel)
    func onFakePitch(model: RawScoreDataModel)
}

class BaseFakeScoringMachine: NSObject {
    weak var delegate: FakeScoringMachineDelegate?
    var lyricModel: LyricModel!
    
    func setLyricsModel(lyricModel: LyricModel) {
        self.lyricModel = lyricModel
        delegate?.onFakeAllRefPitchs(model: lyricModel)
    }
    
    func startScore(songId: Int) {}
    func pauseScore() {}
    func resumeScore() {}
    func setScoreLevel(level: Int) {
        
    }
    func setProgress(progressInMs: UInt) {}
    func pushPitch(pitch: Double) {}
    func reset() {}
}
