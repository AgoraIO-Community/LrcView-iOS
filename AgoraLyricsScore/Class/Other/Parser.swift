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
}
