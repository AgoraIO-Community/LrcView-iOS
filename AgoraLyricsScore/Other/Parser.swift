//
//  File.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

class Parser {
    func parseLyricData(data: Data) -> LyricModel? {
        guard let string = String(data: data, encoding: .utf8) else {
            fatalError("can not verified file type")
        }
        
        if string.first == "<" {
            let parser = XmlParser()
            return parser.parseLyricData(data: data)
        }
        
        if string.first == "[" {
            let parser = LrcParser()
            return parser.parseLyricData(data: data)
        }
        
        fatalError("unknow file type")
    }
}
