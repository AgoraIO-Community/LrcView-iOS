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
    
    /// 计算分数，多次取最大值
    static func calculateMuti(refPitchInterval: Float,
                              userPitchInterval: Float,
                              refPitchs: [Float],
                              userPitchs: [Float]) -> Float? {
        var maxScore: Float = 0
        let start = max(Int(userPitchInterval) - 8, 0)
        let end = Int(userPitchInterval) + 8
        for inter in start...end {
            if let score = calculate(refPitchInterval: refPitchInterval,
                                     userPitchInterval: Float(inter),
                                     realUserPitchInterval: userPitchInterval,
                                     refPitchs: refPitchs,
                                     userPitchs: userPitchs) {
                maxScore = max(maxScore, score)
                print("[inter = \(inter)]得分比：\(score)")
            }
            else {
                print("[inter = \(inter)]得分比：-1")
            }
        }
        
        let finalScore = maxScore * maxScore / 100.0
        return finalScore
    }
    
    /// 计算分数
    /// - Parameters:
    ///   - refPitchInterval: 原唱pitch间隔
    ///   - userPitchInterval: 用户pitch间隔（虚拟，用于放大缩小）
    ///   - realUserPitchInterval: pitch文件真实pitch间隔
    static func calculate(refPitchInterval: Float,
                          userPitchInterval: Float,
                          realUserPitchInterval: Float,
                          refPitchs: [Float],
                          userPitchs: [Float]) -> Float? {
        let refPitchLen = refPitchs.count
        let userPitchLen: Int = userPitchs.count
        
        let config = ScoreClaculator.Config(refPitchLen: refPitchLen,
                                            refPitchInterval: refPitchInterval,
                                            userPitchLen: userPitchLen,
                                            userPitchInterval: userPitchInterval)
        return ScoreClaculator.calculate(config: config,
                                         refPitchs: refPitchs,
                                         userPitchs: userPitchs,
                                         realUserPitchInterval: realUserPitchInterval)
    }
    
    static func calculate(config: Config,
                          refPitchs: [Float],
                          userPitchs: [Float],
                          realUserPitchInterval: Float) -> Float? {
        var result = KgeScoreFinddelayResult_t(usableFlag: 0,
                                               refPitchFirstIdx: 0,
                                               userPitchFirstIdx: 0,
                                               refPicthLeft: 0,
                                               refPicthRight: 0,
                                               userPicthLeft: 0,
                                               userPicthRight: 0)
        
        let ret = find(config: config,
                       refPitchs: refPitchs,
                       userPitchs: userPitchs,
                       result: &result)
        if !ret {
            return nil
        }
        
        KaraokeView.log(text: "usableFlag: \(result.usableFlag)")
        
        if result.usableFlag == 1, result.refPitchFirstIdx >= 0, result.userPitchFirstIdx >= 0 {
            let refPicthLeft = Int(result.refPicthLeft)
            let refPicthRight = Int(result.refPicthRight)
            let userPicthLeft = Int(result.userPicthLeft)
            let userPicthRight = Int(result.userPicthRight)
            let refPitchsNew = Array(refPitchs[refPicthLeft...refPicthRight])
            let userPitchsNew = Array(userPitchs[userPicthLeft...userPicthRight])
            
            let (_, maxValue) = makeMinMaxPitch(pitchs: refPitchsNew)
            KaraokeView.log(text: "refPitchsNew:\(refPitchsNew.count) userPitchsNew:\(userPitchsNew.count) maxValue:\(maxValue)")
            var cumulativeScore: Float = 0.0
            let voiceChanger = VoicePitchChanger()
            var hitCount = 0
            
            for (index, value) in userPitchsNew.enumerated() {
                if index >= refPitchsNew.count {
                    break
                }
                
                if value <= 0 {
                    continue
                }
                
                let score = calculatedBestScorePerTone(index: index,
                                                       value: value,
                                                       config: config,
                                                       refPitchs: refPitchsNew,
                                                       maxValue: maxValue,
                                                       voiceChanger: voiceChanger)
                if score > 0 {
                    hitCount += 1
                }
                cumulativeScore += score
            }
            
            let refTime = Float(refPitchsNew.filter({$0 > 0}).count) * 10
            let userTime = Float(userPitchsNew.count) * realUserPitchInterval
            
            if userTime < refTime * 0.5 {
                return 0.0
            }
            
            let scoreRatio = cumulativeScore / Float(hitCount)
            KaraokeView.log(text: "scoreRatio:\(scoreRatio) = cumulativeScore:\(cumulativeScore) / hitCount: \(hitCount)")
            
            return scoreRatio
        }
        else {
            KaraokeView.log(text: "usableFlag: \(result.usableFlag)")
        }
        return nil
    }
    
    fileprivate static func calculatedBestScorePerTone(index: Int,
                                                       value: Float,
                                                       config: Config,
                                                       refPitchs: [Float],
                                                       maxValue: Float,
                                                       voiceChanger: VoicePitchChanger) -> Float {
        let scale: Float = 1.0
        let radio = config.userPitchInterval / config.refPitchInterval
        let centerIndex = Int(Float(index) * radio)
        let start = max(Int(Float(centerIndex) - scale * radio), 0)
        let end = max(Int(Float(centerIndex) + scale * radio), start)
        
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
                                                            scoreCompensationOffset: 0)
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

