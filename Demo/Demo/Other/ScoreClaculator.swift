//
//  PitchFindDelayWapper.swift
//  Demo
//
//  Created by ZYP on 2023/9/2.
//

import Foundation
import AgoraLyricsScore

class ScoreClaculator {
    typealias ResultType = UnsafeMutablePointer<KgeScoreFinddelayResult_t>
    
    static func calculate(config: Config,
                          refPitchs: [Float],
                          userPitchs: [Float]) -> Float? {
        var result = KgeScoreFinddelayResult_t(usableFlag: 0,
                                               refPitchFirstIdx: 0,
                                               userPitchFirstIdx: 0)

        let ret = find(config: config,
                       refPitchs: refPitchs,
                       userPitchs: userPitchs,
                       result: &result)
        if !ret {
            return nil
        }

        KaraokeView.log(text: "usableFlag: \(result.usableFlag)")

        if result.usableFlag == 1, result.refPitchFirstIdx >= 0, result.userPitchFirstIdx >= 0 {
            let refPitchFirstIdx = result.refPitchFirstIdx
            let userPitchFirstIdx = result.userPitchFirstIdx
            KaraokeView.log(text: "refPitchFirstIdx:\(refPitchFirstIdx) userPitchFirstIdx:\(userPitchFirstIdx)")
            let refPitchsNew = Array(refPitchs[refPitchFirstIdx..<refPitchs.count])
            let userPitchsNew = Array(userPitchs[userPitchFirstIdx..<userPitchs.count])

            let (_, maxValue) = makeMinMaxPitch(pitchs: refPitchsNew)
            KaraokeView.log(text: "refPitchsNew:\(refPitchsNew.count) userPitchsNew:\(userPitchsNew.count) maxValue:\(maxValue)")
            var cumulativeScore: Float = 0.0
            let voiceChanger = VoicePitchChanger()
            for (index, value) in userPitchsNew.enumerated() {
                if index >= refPitchsNew.count {
                    break
                }

                if value <= 0 {
                    continue
                }

                let score = calculatedBestScore(index: index,
                                                value: value,
                                                config: config,
                                                refPitchs: refPitchsNew,
                                                maxValue: maxValue,
                                                voiceChanger: voiceChanger)
                cumulativeScore += score
            }
            
            /// 计算得分占比
            let radio = Int(config.userPitchInterval / config.refPitchInterval)
            let all = (refPitchs.filter({ $0 > 0 }).count * 100) / radio
            let scoreRatio = (cumulativeScore / Float(all)) * 100
            
            KaraokeView.log(text: "scoreRatio:\(scoreRatio) = cumulativeScore:\(cumulativeScore) / all: \(all) all count: \(all * radio / 100) userPotchsCount = \(userPitchs.count)")
            
            return scoreRatio
        }
        else {
            KaraokeView.log(text: "usableFlag: \(result.usableFlag)")
        }
        return nil
    }
    
    fileprivate static func calculatedBestScore(index: Int,
                                                value: Float,
                                                config: Config,
                                                refPitchs: [Float],
                                                maxValue: Float,
                                                voiceChanger: VoicePitchChanger) -> Float {
        
        
        let radio = config.userPitchInterval / config.refPitchInterval
        let centerIndex = Int(Float(index) * radio)
        let start = max(Int(Float(centerIndex) - 2.0 * radio), 0)
        let end = max(Int(Float(start) + 4.0 * radio), start)
        
        var score: Float = 0
        var offset: Double = 0
        var n: Double = 0
        for refIndex in start..<end {
            if refIndex >= refPitchs.count {
                break
            }
            
            let refPitch = refPitchs[refIndex]
            if refPitch <= 0 {
                continue
            }
            
            let valueAfterVoiceChange = voiceChanger.handlePitch(stdPitch:Double(refPitch),
                                                                 voicePitch: Double(value),
                                                                 stdMaxPitch: Double(maxValue),
                                                                 newOffset: offset,
                                                                 newN: n)
            
            let currentScore = ToneCalculator.calculedScore(voicePitch: valueAfterVoiceChange,
                                                            stdPitch: Double(refPitch),
                                                            scoreLevel: 10,
                                                            scoreCompensationOffset: 30)
            if currentScore >= score {
                offset = voiceChanger.offset
                n = voiceChanger.n
            }
            
            score = max(currentScore, score)
        }
        print("best score \(score)")
        return score
    }
    
    fileprivate static func find(config: Config,
                                 refPitchs: [Float],
                                 userPitchs: [Float],
                                 result: ResultType) -> Bool {
        var cfg = KgeScoreFinddelayCfg_t()
        cfg.refPitchLen = config.refPitchLen
        cfg.refPitchInterval = config.refPitchInterval
        cfg.userPitchLen = config.userPitchLen
        cfg.userPitchInterval = config.userPitchInterval
        cfg.minValidLen = config.minValidLen
        cfg.minValidRatio = config.minValidRatio
        cfg.corrThr = config.corrThr
        cfg.effCorrCntThr = config.effCorrCntThr
        cfg.debugFlag = config.debugFlag
        
        print("cfg.refPitchLen:\(cfg.refPitchLen) cfg.refPitchInterval:\(cfg.refPitchInterval) cfg.userPitchLen:\(cfg.userPitchLen) cfg.userPitchInterval:\(cfg.userPitchInterval) cfg.minValidLen:\(cfg.minValidLen) cfg.minValidRatio:\(cfg.minValidRatio) cfg.corrThr:\(cfg.corrThr) cfg.effCorrCntThr:\(cfg.effCorrCntThr) cfg.debugFlag:\(cfg.debugFlag)")
        
        var rawRefPitch = refPitchs
        var rawUserPitch = userPitchs
        
        let refPitchLen = cfg.refPitchLen
        var tmpBuffer1 = Array<Float>.init(repeating: 0, count: refPitchLen)
        
        let userPitchLen = cfg.userPitchLen
        var tmpBuffer2 = Array<Float>.init(repeating: 0, count: userPitchLen)
        
        let status = agora_kge_score_finddelay(&cfg, &rawRefPitch, &tmpBuffer1, &rawUserPitch, &tmpBuffer2, result)
        
        if status == 0 {
            KaraokeView.log(text: "Score Find Delay Success!")
        } else {
            KaraokeView.log(text: "Score Find Delay Failed!")
        }
        
        let success = status == 0
        return success
    }
    
    static func makeMinMaxPitch(pitchs: [Float]) -> (Float, Float) {
        let maxValue = pitchs.max() ?? 0
        let minValue = pitchs.min() ?? 0
        return (minValue, maxValue)
    }
    
    struct Config {
        // length of the array
        let refPitchLen: Int
        // ref. pitch sample interval, in ms
        let refPitchInterval: Float
        // length of the array userPitch
        let userPitchLen: Int
        // user pitch sample interval, in ms
        let userPitchInterval: Float
        // minimum length of voiced pitches, in ms
        let minValidLen: Float = 2000.0
        // minimum requirement of voiced pitches vs ref. pitches
        let minValidRatio: Float = 0.1
        // threshold on the correlation coefficient to assure reliable alignment
        let corrThr: Float = 0.12
        // threshold on the effective correlation points
        let effCorrCntThr: Int32 = 50
        // flag to enable the module's debug-mode
        let debugFlag: Int32 = 1
        
        init(refPitchLen: Int,
             refPitchInterval: Float,
             userPitchLen: Int,
             userPitchInterval: Float) {
            self.refPitchLen = refPitchLen
            self.refPitchInterval = refPitchInterval
            self.userPitchLen = userPitchLen
            self.userPitchInterval = userPitchInterval
        }
    }
}


