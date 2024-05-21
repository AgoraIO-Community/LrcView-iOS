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
        let firstPitchDataEndTime = firstPitchDataStartTime + (pitchModel.pitchDatas.first?.duration  ?? 0)
        
        if !includeCopyrightSentence { /** 移除版权信息类型的句子 **/
            /// find a actual start lineIndex
            guard let firstIndex = lyricModel.lines.enumerated().first(where: { (_, element) in
                return firstPitchDataStartTime <= element.endTime && firstPitchDataEndTime <= element.endTime
            }).map({ $0.offset }) else {
                Log.errorText(text: "no valid line", tag: logTag)
                return lyricModel
            }
            
            lyricModel.lines = lyricModel.lines.enumerated().filter({ (index, _) in
                return index >= firstIndex
            }).map({ $0.element })
        }
        
        return lyricModel
    }
}
