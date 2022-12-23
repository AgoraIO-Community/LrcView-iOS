//
//  Extensions.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

extension String {
    // 字符串截取
    func textSubstring(startIndex: Int, length: Int) -> String {
        let startIndex = index(self.startIndex, offsetBy: startIndex)
        let endIndex = index(startIndex, offsetBy: length)
        let subvalues = self[startIndex ..< endIndex]
        return String(subvalues)
    }
}

extension LyricModel {
    /// 无歌词
    var isEmpty: Bool {
        return name == "" &&
        singer == "" &&
        lines.count == 0 &&
        !hasPitch &&
        duration == 0 &&
        preludeEndPosition == 0
    }
    
    
}

extension LyricLineModel {
    var endTime: Int {
        beginTime + duration
    }
}
