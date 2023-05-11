//
//  PitchParser.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/4/13.
//

import Foundation

class PitchParser {
    private let logTag = "PitchParser"
    
    func parse(data: Data) -> PitchModel? {
        let headLen = 12
        if (data.count - headLen) % 8 != 0 {
            Log.errorText(text: "pitchFileData count issue", tag: logTag)
            return nil
        }
        
        /// head info
        let headData = data.subdata(in: 0..<headLen)
        let version = headData[0..<4].withUnsafeBytes { $0.load(as: Int32.self) }
        let timeInterval = headData[4..<8].withUnsafeBytes { $0.load(as: Int32.self) }
        let reserved = headData[8..<12].withUnsafeBytes { $0.load(as: Int32.self) }
        
        /// content
        let contentData = data.subdata(in: headLen..<data.count)
        var values: [Double] = []
        for i in stride(from: 0, to: contentData.count, by: 8) {
            let value = contentData[i..<i+8].withUnsafeBytes { $0.load(as: Double.self) }
            values.append(value)
        }
        
        let duration = values.count * Int(timeInterval)
        let items = values.enumerated().map({ PitchItem(value: $0.1, beginTime: $0.0 * Int(timeInterval), duration: Int(timeInterval)) })
        let model = PitchModel(version: Int(version),
                               timeInterval: Int(timeInterval),
                               reserved: Int(reserved),
                               duration: duration,
                               items: items)
        return model
    }
}
