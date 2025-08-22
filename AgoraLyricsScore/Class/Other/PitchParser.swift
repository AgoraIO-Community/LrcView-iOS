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
        /// 把data转成PitchModel
        guard !data.isEmpty else {
            return nil
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDict = jsonObject as? [String: Any],
                  let pitchDatasArray = jsonDict["pitchDatas"] as? [[String: Any]] else {
                Log.errorText(text: "Invalid JSON format: missing pitchDatas array", tag: logTag)
                return nil
            }
            
            var pitchDatas: [KrcPitchData] = []
            
            for pitchDataDict in pitchDatasArray {
                // 处理pitch字段 - 支持Int和Double
                guard let pitch = (pitchDataDict["pitch"] as? Double) ?? 
                                  (pitchDataDict["pitch"] as? Int).map(Double.init) else {
                    Log.errorText(text: "Invalid pitch data format in array", tag: logTag)
                    continue
                }

                // 处理startTime字段 - 支持Int和UInt  
                guard let startTime = (pitchDataDict["startTime"] as? UInt) ?? 
                                      (pitchDataDict["startTime"] as? Int).map(UInt.init) else {
                    Log.errorText(text: "Invalid pitch data format in array", tag: logTag)
                    continue
                }

                // 处理duration字段 - 支持Int和UInt
                guard let duration = (pitchDataDict["duration"] as? UInt) ?? 
                                     (pitchDataDict["duration"] as? Int).map(UInt.init) else {
                    Log.errorText(text: "Invalid pitch data format in array", tag: logTag)
                    continue
                }
                
                let krcPitchData = KrcPitchData(pitch: pitch, startTime: startTime, duration: duration)
                pitchDatas.append(krcPitchData)
            }
            
            return PitchModel(pitchDatas: pitchDatas)
            
        } catch let error {
            Log.error(error: error.localizedDescription, tag: logTag)
            return nil
        }
    }
}


extension PitchParser {
    struct PitchModel {
        let pitchDatas: [KrcPitchData]
    }
}

