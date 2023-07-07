//
//  PitchMerge.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/4/13.
//

import Foundation

class PitchMerge {
    private let logTag = "PitchMerge"
    
    /// merge
    /// - Parameters:
    ///   - mergeCountInLrc: How much data to merge, only in lrc file
    /// - Returns: `LyricModel`
    func merge(model: LyricModel, pitchModel: PitchModel, mergeCountInLrc: Int = 10) -> LyricModel {
        guard PitchMerge.isValidMatchData(model: model, pitchModel: pitchModel) else {
            let text = """
            handle of merge was skip, is not Valid Match file between Lyric and Pitch pitchItems: \(pitchModel.items.count) songName: \(model.name) lines:\(model.lines.count) line.last.beginTime:\(model.lines.last?.beginTime ?? -999)
            """
            Log.errorText(text: text)
            return model
        }
        
        if model.sourceType == .xml {
            return mergeXML(model: model, pitchModel: pitchModel)
        }
        else {
            if PitchMerge.isEnhancedLrc(model: model) {
                return mergeEnhancedLRC(model: model, pitchModel: pitchModel)
            }
            else {
                return mergeLRC(model: model, pitchModel: pitchModel, mergeCount: mergeCountInLrc)
            }
        }
    }
    
    private func mergeXML(model: LyricModel, pitchModel: PitchModel) -> LyricModel {
        guard !model.lines.isEmpty else {
            return model
        }
        
        var hasPitch = false
        for line in model.lines {
            for tone in line.tones {
                if let array = findPitchs(beginTime: tone.beginTime,
                                          duration: tone.duration,
                                          pitchItems: pitchModel.items,
                                          durationPerValue: pitchModel.timeInterval) {
                    let values = array.map({ $0.value })
                    let pitch = calculateAverage(pitchs: values)
                    tone.pitch = pitch
                    if pitch > 0 {
                        hasPitch = true
                    }
                }
            }
        }
        model.hasPitch = hasPitch
        return model
    }
    
    private func mergeEnhancedLRC(model: LyricModel, pitchModel: PitchModel) -> LyricModel {
        guard !model.lines.isEmpty else {
            return model
        }
        
        /// fix duration of last line and last tone
        guard let duration = findLastLineDuration(beginTime: model.lines.last!.beginTime,
                                                  pitchItems: pitchModel.items,
                                                  durationPerValue: pitchModel.timeInterval) else {
            Log.errorText(text: "mergeEnhancedLRC handle of merge was skip, findLastLineDuration fail")
            return model
        }
        
        model.lines.last!.duration = duration
        model.lines.last!.tones.last!.duration = model.lines.last!.endTime - model.lines.last!.tones.last!.beginTime
        Log.debug(text: "last line duration: \(duration)", tag: logTag)
        
        /// use xml method to handle pitch
        return mergeXML(model: model, pitchModel: pitchModel)
    }
    
    private func mergeLRC(model: LyricModel, pitchModel: PitchModel, mergeCount: Int) -> LyricModel {
        guard !model.lines.isEmpty else {
            return model
        }
        
        
        guard let duration = findLastLineDuration(beginTime: model.lines.last!.beginTime,
                                                  pitchItems: pitchModel.items,
                                                  durationPerValue: pitchModel.timeInterval) else {
            Log.errorText(text: "mergeLRC handle of merge was skip, findLastLineDuration fail")
            return model
        }
        
        
        model.lines.last!.duration = duration
        Log.debug(text: "last line duration: \(duration)", tag: logTag)
        
        let durationPerValue = pitchModel.timeInterval
        var hasPitch = false
        for line in model.lines {
            if let items = findPitchs(beginTime: line.beginTime,
                                      duration: line.duration,
                                      pitchItems: pitchModel.items,
                                      durationPerValue: pitchModel.timeInterval) {
                var mergedArray = [LyricToneModel]()
                for i in stride(from: 0, to: items.count, by: mergeCount) {
                    let endIndex = min(i + mergeCount, items.count)
                    let subArray = items[i..<endIndex]
                    let beginTime = subArray.first!.beginTime
                    let duration = subArray.count * durationPerValue
                    let avgPicth = calculateAverage(pitchs: subArray.map({ $0.value }))
                    let tone = LyricToneModel(beginTime: beginTime,
                                              duration: duration,
                                              word: "",
                                              pitch: avgPicth,
                                              lang: .unknow,
                                              pronounce: "")
                    mergedArray.append(tone)
                }
                line.tones = mergedArray
                hasPitch = line.tones.contains(where: { $0.pitch > 0 })
            }
        }
        model.hasPitch = hasPitch
        return model
    }
    
    /// 指定时间找出音高集合
    private func findPitchs(beginTime: Int,
                            duration: Int,
                            pitchItems: [PitchItem],
                            durationPerValue: Int) -> [PitchItem]? {
        let startIndex = beginTime / durationPerValue
        let endIndex = (beginTime + duration) / durationPerValue
        
        if endIndex >= pitchItems.count { /// out bounds
            Log.error(error: "findPitchs error: out bounds", tag: logTag)
            return nil
        }
        
        let selectedPitchs = pitchItems[startIndex...endIndex]
        return Array(selectedPitchs)
    }
    
    /// 计算音高平均值
    private func calculateAverage(pitchs: [Double]) -> Double {
        let temp = pitchs.filter({ $0 > 0 })
        let sum = temp.reduce(0.0, +)
        let count = temp.count == 0 ? 1 : Double(temp.count)
        return sum / Double(count)
    }
    
    /// 计算最后一句的时长
    private func findLastLineDuration(beginTime: Int,
                                      pitchItems: [PitchItem],
                                      durationPerValue: Int) -> Int? {
        let startIndex = beginTime / durationPerValue
        let count = pitchItems.count
        var index = count - 1
        while index > startIndex {
            if pitchItems[index].value > 0 {
                break
            }
            index -= 1
        }
        
        let duration = (index - startIndex) * durationPerValue
        if duration <= 0 {
            return nil
        }
        return duration
    }
    
    static func isEnhancedLrc(model: LyricModel) -> Bool {
        guard model.sourceType == .lrc else {
            return false
        }
        // Define a variable num to record the number of lines with pitch information
        var num = 0
        for line in model.lines {
            if !line.tones.isEmpty {
                num += 1
            }
            // If num reaches or exceeds 3, it means that this is an enhanced LRC format
            if num >= 3 {
                return true
            }
        }
        // If all lines are traversed without returning true, it means that this is not an enhanced LRC format
        return false
    }
    
    static func isValidMatchData(model: LyricModel, pitchModel: PitchModel) -> Bool {
        guard let lastLineBeginTime = model.lines.last?.beginTime else {
            return false
        }
        
        /// size issue
        let pitchNum = lastLineBeginTime / pitchModel.timeInterval
        if pitchModel.items.count < pitchNum {
            return false
        }
        
        return true
    }
}
