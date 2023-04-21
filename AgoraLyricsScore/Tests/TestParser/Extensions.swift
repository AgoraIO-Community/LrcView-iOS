//
//  Extensions.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2022/12/22.
//

import Foundation

class TG {
    
}

extension Bundle {
    static var current: Bundle {
        Bundle(for: TG.self)
    }
}

extension Data {
    func subdata(in range: CountableClosedRange<Data.Index>) -> Data {
        return self.subdata(in: range.lowerBound..<range.upperBound + 1)
    }
}


