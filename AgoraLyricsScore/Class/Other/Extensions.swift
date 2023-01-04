//
//  Extensions.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/21.
//

import Foundation

class AgoraLyricsScore {}

extension String {
    // 字符串截取
    func textSubstring(startIndex: Int, length: Int) -> String {
        let startIndex = index(self.startIndex, offsetBy: startIndex)
        let endIndex = index(startIndex, offsetBy: length)
        let subvalues = self[startIndex ..< endIndex]
        return String(subvalues)
    }
}

extension LyricLineModel {
    var endTime: Int {
        beginTime + duration
    }
}

extension LyricToneModel {
    var endTime: Int {
        beginTime + duration
    }
}

extension Bundle {
    static var currentBundle: Bundle {
        let bundle = Bundle(for: AgoraLyricsScore.self)
        let path = bundle.path(forResource: "AgoraLyricsScore", ofType: "bundle")!
        return Bundle(path: path)!
    }
    
    func image(name: String) -> UIImage? {
        return UIImage(named: name, in: self, compatibleWith: nil)
    }
}
