//
//  File.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

class Parser {
    private let logTag = "Parser"
    func parseLyricData(data: Data) -> LyricModel? {
        guard data.count > 0 else {
            Log.errorText(text: "data.count == 0", tag: logTag)
            return nil
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            Log.errorText(text: "can not verified file type", tag: logTag)
            return nil
        }
        
        if string.first == "<" { /** XML格式 **/
            let parser = XmlParser()
            return parser.parseLyricData(data: data)
        }
        
        if string.first == "[" { /** LRC格式 **/
            let parser = LrcParser()
            return parser.parseLyricData(data: data)
        }
        
        fatalError("unknow file type")
    }
    
    func parseLyricData(krcFileData: Data,
                        pitchFileData: Data,
                        includeCopyrightSentence: Bool = true) -> LyricModel? {
        guard krcFileData.count > 0 else {
            Log.errorText(text: "krcFileData.count == 0", tag: logTag)
            return nil
        }
        
        guard pitchFileData.count > 0 else {
            Log.errorText(text: "pitchFileData.count == 0", tag: logTag)
            return nil
        }
        
        let krcPaeser = KRCParser()
        guard let lyricModel = krcPaeser.parse(krcFileData: krcFileData) else {
            return nil
        }
        
        let pitchParser = PitchParser()
        guard let pitchModel = pitchParser.parse(fileContent: pitchFileData) else {
            return nil
        }
        
        lyricModel.pitchDatas = pitchModel.pitchDatas
        lyricModel.hasPitch = !pitchModel.pitchDatas.isEmpty
        lyricModel.preludeEndPosition = pitchModel.pitchDatas.first?.startTime ?? 0
        
        if !includeCopyrightSentence { /** 移除版权信息类型的句子 **/
            lyricModel.lines = lyricModel.lines.filter { line in
                return line.beginTime > (pitchModel.pitchDatas.first?.startTime ?? 0)
            }
        }
        
        return lyricModel
    }
}
