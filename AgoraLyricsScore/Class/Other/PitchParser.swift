//
//  PitchParser.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2024/5/9.
//

import Foundation

class PitchParser {
    fileprivate let logTag = "PitchParser"
    
    func parse(fileContent data: Data) -> PitchModel? {
        /// 把data转成PitchParser
        guard !data.isEmpty else {
            Log.errorText(text: "PitchParser.parse fail, data is empty", tag: logTag)
            return nil
        }
        
        do {
            let pitchModel = try JSONDecoder().decode(PitchModel.self, from: data)
            return pitchModel
        } catch let error {
            Log.error(error: error.localizedDescription, tag: logTag)
            return nil
        }
    }
}


extension PitchParser {
    struct PitchModel: Codable {
        let pitchDatas: [KrcPitchData]
    }
}

