//
//  File.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

class Parser {
    private let logTag = "Parser"
    
    func parseLyricData(krcFileData: Data,
                        pitchFileData: Data?,
                        includeCopyrightSentence: Bool = true) -> LyricModelEx? {
        guard krcFileData.count > 0 else {
            Log.errorText(text: "krcFileData.count == 0", tag: logTag)
            return nil
        }
        
        let krcPaeser = KRCParser()
        guard let lyricModel = krcPaeser.parse(krcFileData: krcFileData) else {
            return nil
        }
        
        guard let pitchFileData = pitchFileData, !pitchFileData.isEmpty else { /** if `pitchFileData` is nil **/
            return lyricModel
        }
        
        let pitchParser = PitchParser()
        guard let pitchModel = pitchParser.parse(fileContent: pitchFileData) else {
            return nil
        }
        
        lyricModel.pitchDatas = pitchModel.pitchDatas
        lyricModel.hasPitch = !pitchModel.pitchDatas.isEmpty
        lyricModel.preludeEndPosition = pitchModel.pitchDatas.first?.startTime ?? 0
        
        let firstPitchDataStartTime = pitchModel.pitchDatas.first?.startTime ?? 0
        if !includeCopyrightSentence { /** 移除版权信息类型的句子 **/
            let lines = lyricModel.lines.map({ $0.beginTime })
            let firstIndex = getMostCloseToFirstPitchIndex(lineBegins: lines, firstPitchStartTime: firstPitchDataStartTime)
            lyricModel.lines = lyricModel.lines.enumerated().filter({ (index, _) in
                return index >= firstIndex
            }).map({ $0.element })
        }
        
        return lyricModel
    }
    
    func getMostCloseToFirstPitchIndex(lineBegins: [UInt], firstPitchStartTime: UInt) -> Int {
        /**
            用firstPitchStartTime，和lineBegins中的每一个进行对比，找到lineBegins中距离firstPitchStartTime最近的那个index
         **/
        var minDiff = UInt.max
        var firstMinIndex = 0
        for (index, lineBegin) in lineBegins.enumerated() {
            let diff = UInt(abs(Int32(lineBegin) - Int32(firstPitchStartTime)))
            if diff < minDiff {
                minDiff = diff
                firstMinIndex = index
            }
        }
        return firstMinIndex
    }
}
