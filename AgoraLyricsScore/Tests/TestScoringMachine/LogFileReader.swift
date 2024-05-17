//
//  LogFileReader.swift
//  AgoraLyricsScore-Unit-Tests
//
//  Created by ZYP on 2023/11/8.
//

import Foundation

class LogFileReader {
    struct Item {
        let progress: Int?
        let pitch: Double?
    }
    
    static func readFromFile(fileName: String) -> (result1: [Item], result2: [Item]) {
        let name = "TestLogFile/\(fileName).txt"
        let fileUrl = URL(fileURLWithPath: Bundle.current.path(forResource: name, ofType:nil)!)
        let fileData = try! Data(contentsOf: fileUrl)
        let string = String(data: fileData, encoding: .utf8)!
        let array = string.split(separator: "\n").map({ String($0) })
        
        
        var result1 = [Item]()
        var result2 = [Item]()
        var songIndex: Int = -1
        for str in array {
            if str.contains("[ALS][I][KaraokeViewEx]: setLyricData") {
                if songIndex == -1 {
                    songIndex = 0
                    continue
                }
                if songIndex == 0 {
                    songIndex = 1
                    continue
                }
            }
            if songIndex == -1 { continue }
            
            if str.contains("[ALS][D][ScoringMachine]: progress: ") {
                let strVal = String(str.split(separator: " ").last!)
                let progress = Int(strVal)!
                let item = Item(progress: progress, pitch: nil)
                if songIndex == 0 {
                    result1.append(item)
                }
                else {
                    result2.append(item)
                }
                continue
            }
            
            if str.contains("[ALS][D][ScoringMachine]: pitch:") {
                let parts = str.components(separatedBy: "pitch: ")
                if let lastPart = parts.last {
                    let parts2 = lastPart.components(separatedBy: " after: ")
                    if let firstPart = parts2.first {
                        if let pitch = Double(firstPart) {
                            let item = Item(progress: nil, pitch: pitch)
                            if songIndex == 0 {
                                result1.append(item)
                            }
                            else {
                                result2.append(item)
                            }
                        }
                    }
                }
            }
        }
        return (result1, result2)
    }
}

