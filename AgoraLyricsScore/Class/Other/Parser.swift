//
//  File.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

class Parser {
    private let logTag = "Parser"
    
    /// parseLyricData
    /// - Parameters:
    ///   - data: binary data of xml/lrc file
    ///   - pitchFileData: binary data of pitch file
    /// - Returns: `LyricModel`
    func parseLyricData(data: Data,
                        pitchFileData: Data?) -> LyricModel? {
        guard data.count > 0 else {
            Log.errorText(text: "data.count == 0", tag: logTag)
            return nil
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            Log.errorText(text: "can not verified file type", tag: logTag)
            return nil
        }
        
        var pitchModel: PitchModel?
        if let pitchFileData = pitchFileData {
            let pitchParser = PitchParser()
            pitchModel = pitchParser.parse(data: pitchFileData)
        }
        
        var model: LyricModel?
        if string.first == "<" { /** XML **/
            let parser = XmlParser()
            model = parser.parseLyricData(data: data)
        }
        
        if string.first == "[" { /** LRC **/
            let parser = LrcParser()
            model = parser.parseLyricData(data: data)
        }
        
        if var model = model, let pitchModel = pitchModel { /** merge **/
            let merge = PitchMerge()
            model = merge.merge(model: model, pitchModel: pitchModel)
        }
        
        return model
    }
}
