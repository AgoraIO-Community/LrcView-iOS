//
//  ScoringMachine+DataHandle.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/2/2.
//

import Foundation

extension ScoringMachine {
    /// 创建Scoring内部数据
    static func createData(data: LyricModel) -> ([UInt], [Info]) {
        var array = [Info]()
        for (index, pitchData) in data.pitchDatas.enumerated() {
            let info = Info(beginTime: pitchData.startTime,
                            duration: pitchData.duration,
                            word: "\(index)",
                            pitch: pitchData.pitch,
                            drawBeginTime: pitchData.startTime,
                            drawDuration: pitchData.duration)
            array.append(info)
        }
        let lineEndTimes = data.lines.map({ $0.endTime })
        return (lineEndTimes, array)
    }
    
    func makeHighlightInfos(progress: UInt,
                            hitedInfo: Info,
                            currentVisiableInfos: [Info],
                            currentHighlightInfos: [Info]) -> [Info] {
        let pitchDuration = 50
        if let preHitInfo = currentHighlightInfos.last, preHitInfo.beginTime == hitedInfo.beginTime { /** 判断是否需要追加 **/
            let newDrawBeginTime = max(progress, preHitInfo.beginTime)
            let distance = abs(Int(newDrawBeginTime) - Int(preHitInfo.drawEndTime))
            if distance < pitchDuration { /** 追加 **/
                /// if distance less than 50ms, it will be added to the previous pitch, and add the distance to the drawDuration
                let drawDuration = min(preHitInfo.drawDuration + UInt(pitchDuration) + UInt(distance), preHitInfo.duration)
                preHitInfo.drawDuration = drawDuration
                return currentHighlightInfos
            }
        }
        
        /** 新建 **/
        let stdInfo = hitedInfo
        let drawBeginTime = max(progress, stdInfo.beginTime)
        let drawDuration = min(UInt(pitchDuration), stdInfo.duration)
        let info = Info(beginTime: stdInfo.beginTime,
                        duration: stdInfo.duration,
                        word: stdInfo.word,
                        pitch: stdInfo.pitch,
                        drawBeginTime: drawBeginTime,
                        drawDuration: drawDuration)
        var temp = currentHighlightInfos
        temp.append(info)
        return temp
    }
    
    /// 生成DrawInfo
    /// - Returns: (visiableDrawInfos, highlightDrawInfos, currentVisiableInfos, currentHighlightInfos)
    func makeInfos(progress: UInt,
                   dataList: [Info],
                   currentHighlightInfos: [Info],
                   defaultPitchCursorX: CGFloat,
                   widthPreMs: CGFloat,
                   canvasViewSize: CGSize,
                   standardPitchStickViewHeight: CGFloat,
                   minPitch: Double,
                   maxPitch: Double) -> ([DrawInfo], [DrawInfo], [Info], [Info]) {
        /// 视图最左边到游标这段距离对应的时长
        let defaultPitchCursorXTime = UInt(defaultPitchCursorX / widthPreMs)
        /// 游标到视图最右边对应的时长
        let remainTime = UInt((canvasViewSize.width - defaultPitchCursorX) / widthPreMs)
        /// 需要显示音高的开始时间
        let beginTime = UInt(max(Int(progress) - Int(defaultPitchCursorXTime), 0))
        /// 需要显示音高的结束时间
        let endTime = progress + remainTime
        
        let currentVisiableInfos = filterInfos(infos: dataList,
                                               beginTime: beginTime,
                                               endTime: endTime)
        let highlightInfos = filterInfos(infos: currentHighlightInfos,
                                         beginTime: beginTime,
                                         endTime: endTime)
        
        var visiableDrawInfos = [DrawInfo]()
        for info in currentVisiableInfos {
            let rect = calculateDrawRect(progress: progress,
                                         info: info,
                                         standardPitchStickViewHeight: standardPitchStickViewHeight,
                                         widthPreMs: widthPreMs,
                                         canvasViewSize: canvasViewSize,
                                         minPitch: minPitch,
                                         maxPitch: maxPitch)
            let drawInfo = DrawInfo(rect: rect)
            visiableDrawInfos.append(drawInfo)
        }
        
        var highlightDrawInfos = [DrawInfo]()
        for info in highlightInfos {
            let rect = calculateDrawRect(progress: progress,
                                         info: info,
                                         standardPitchStickViewHeight: standardPitchStickViewHeight,
                                         widthPreMs: widthPreMs,
                                         canvasViewSize: canvasViewSize,
                                         minPitch: minPitch,
                                         maxPitch: maxPitch)
            let drawInfo = DrawInfo(rect: rect)
            highlightDrawInfos.append(drawInfo)
        }
        
        return (visiableDrawInfos, highlightDrawInfos, currentVisiableInfos, highlightInfos)
    }
    
    /// 生成最大、最小Pitch值
    /// - Returns: (minPitch, maxPitch)
    func makeMinMaxPitch(dataList: [Info]) -> (Double, Double) {
        /** set value **/
        let pitchs = dataList.filter({ $0.word != " " }).map({ $0.pitch })
        let maxValue = pitchs.max() ?? 0
        let minValue = pitchs.min() ?? 0
        return (minValue, maxValue)
    }
    
    /// 获取击中数据
    func getHitedInfo(progress: UInt,
                      currentVisiableInfos: [Info]) -> Info? {
        let pitchBeginTime = progress
        return currentVisiableInfos.first { info in
            return pitchBeginTime >= info.drawBeginTime && pitchBeginTime <= info.endTime
        }
    }
    
    /// 查找当前句子的索引
    /// - Parameters:
    /// - Returns: `nil` 表示不合法, ==`lineEndTimes.count` 表示最后一句已经结束
    func findCurrentIndexOfLine(progress: Int, lineEndTimes: [Int]) -> Int? {
        if lineEndTimes.isEmpty {
            return nil
        }
        
        if progress > lineEndTimes.last! {
            return lineEndTimes.count
        }
        
        if progress <= lineEndTimes.first! {
            return 0
        }
        
        var lastEnd = 0
        for (offset, value) in lineEndTimes.enumerated() {
            if progress > lastEnd, progress <= value  {
                return offset
            }
            lastEnd = value
        }
        return nil
    }
    
    /// 筛选指定时间下的infos
    func filterInfos(infos: [Info],
                     beginTime: UInt,
                     endTime: UInt) -> [Info] {
        var result = [Info]()
        for info in infos {
            if info.drawBeginTime >= endTime {
                break
            }
            if info.endTime <= beginTime {
                continue
            }
            result.append(info)
        }
        return result
    }
    
    func calculateActualSpeakerPitch(speakerPitch: UInt8, refPitch: Double) -> Double {
        guard speakerPitch != 0 else {
            Log.errorText(text: "speakerPitch:\(speakerPitch)", tag: logTag)
            fatalError("speakerPitch must > 0, <= 100")
        }
        
        guard speakerPitch <= 100 else {
            Log.errorText(text: "speakerPitch:\(speakerPitch)", tag: logTag)
            fatalError("speakerPitch must > 0, <= 100")
        }
        
        var actualspeakerPitch: Double = 0
        switch speakerPitch {
        case 1:
            actualspeakerPitch = refPitch - 2
            break
        case 2:
            actualspeakerPitch = refPitch - 1
            break
        case 3:
            actualspeakerPitch = refPitch - 0
            break
        case 4:
            actualspeakerPitch = refPitch + 1
            break
        case 5:
            actualspeakerPitch = refPitch + 2
            break
        default: /** [6,100] */
            actualspeakerPitch = Double(speakerPitch)
            break
        }
        return actualspeakerPitch
    }
}

extension ScoringMachine { /** ui 位置 **/
    /// 计算音准线的位置
    func calculateDrawRect(progress: UInt,
                           info: Info,
                           standardPitchStickViewHeight: CGFloat,
                           widthPreMs: CGFloat,
                           canvasViewSize: CGSize,
                           minPitch: Double,
                           maxPitch: Double) -> CGRect {
        let beginTime = info.drawBeginTime
        let duration = info.drawDuration
        let pitch = info.pitch
        
        /// 视图最左边到游标这段距离对应的时长
        let defaultPitchCursorXTime = Int(defaultPitchCursorX / widthPreMs)
        let x = CGFloat(Int(beginTime) - (Int(progress) - defaultPitchCursorXTime)) * widthPreMs
        let y = calculatedY(pitch: pitch,
                            viewHeight: canvasViewSize.height,
                            minPitch: minPitch,
                            maxPitch: maxPitch,
                            standardPitchStickViewHeight: standardPitchStickViewHeight) ?? 0 - (standardPitchStickViewHeight / 2)
        let w = widthPreMs * CGFloat(duration)
        let h = standardPitchStickViewHeight
        
        let rect = CGRect(x: x, y: y, width: w, height: h)
        return rect
    }
    
    /// 根据`歌曲参考音高`计算`音准线view`的在父视图中的Y坐标
    /// - Parameters:
    ///   - pitch: 原唱歌曲的参考音高
    ///   - viewHeight: 父视图的实际高度
    ///   - minPitch: 对应歌曲音高中的最小值
    ///   - maxPitch: 对应歌曲音高中的最大值
    ///   - standardPitchStickViewHeight: `音准线view`的高度
    /// - Returns:`音准线view`在父视图中的Y坐标值
    func calculatedY(pitch: Double,
                     viewHeight: CGFloat,
                     minPitch: Double,
                     maxPitch: Double,
                     standardPitchStickViewHeight: CGFloat) -> CGFloat? {
        if viewHeight <= 0 {
            Log.errorText(text: "calculatedY viewHeight invalid \(viewHeight)", tag: logTag)
            return nil
        }
        
        /** 计算扩展 **/
        let pitchPerPoint = (CGFloat(maxPitch) - CGFloat(minPitch)) / viewHeight
        let extends = pitchPerPoint * standardPitchStickViewHeight
        
        if pitch < minPitch {
            return viewHeight - extends/2
        }
        
        if pitch > maxPitch {
            return extends/2
        }
        
        /** 计算实际的渲染高度 **/
        let rate = (pitch - minPitch) / (maxPitch - minPitch)
        let renderingHeight = viewHeight - extends
        
        /** 计算距离 （从bottom到top） **/
        let distance = extends/2 + (renderingHeight * rate)
        
        /** 计算y **/
        let y = viewHeight - distance
        
        if y.isNaN {
            Log.errorText(text: "calculatedY result invalid pitch:\(pitch) viewHeight:\(viewHeight) minPitch:\(minPitch) maxPitch:\(maxPitch) standardPitchStickViewHeight:\(standardPitchStickViewHeight)", tag: logTag)
            return nil
        }
        
        return y
    }
}
