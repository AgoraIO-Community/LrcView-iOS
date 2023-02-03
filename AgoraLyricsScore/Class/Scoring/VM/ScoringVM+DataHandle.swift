//
//  ScoringVM+DataHandle.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/2/2.
//

import Foundation

extension ScoringVM {
    /// 创建Scoring内部数据
    ///   - shouldFixTime: 是否要修复时间异常问题
    ///   - return: (行结束时间, 字模型)
    static func createData(data: LyricModel, shouldFixTime: Bool = true) -> ([Int], [Info]) {
        var array = [Info]()
        var lineEndTimes = [Int]()
        var preEndTime = 0
        for line in data.lines {
            for tone in line.tones {
                var beginTime = tone.beginTime
                var duration = tone.duration
                if shouldFixTime { /** 时间异常修复 **/
                    if beginTime < preEndTime {
                        /// 取出endTime文件原始值
                        let endTime = tone.endTime
                        beginTime = preEndTime
                        duration = endTime - beginTime
                    }
                }
                
                let info = Info(beginTime: beginTime,
                                duration: duration,
                                word: tone.word,
                                pitch: tone.pitch,
                                drawBeginTime: tone.beginTime,
                                drawDuration: tone.duration,
                                isLastInLine: tone == line.tones.last)
                
                preEndTime = tone.endTime
                
                array.append(info)
            }
            lineEndTimes.append(preEndTime)
        }
        return (lineEndTimes, array)
    }
    
    func makeHighlightInfos(progress: Int,
                            hitedInfo: Info,
                            pitchDuration: Int,
                            currentVisiableInfos: [Info],
                            currentHighlightInfos: [Info]) -> [Info] {
        if let preHitInfo = currentHighlightInfos.last, preHitInfo.beginTime == hitedInfo.beginTime { /** 判断是否需要追加 **/
            let newDrawBeginTime = max(progress - pitchDuration, preHitInfo.beginTime)
            let distance = newDrawBeginTime - preHitInfo.drawEndTime
            if distance < pitchDuration { /** 追加 **/
                let drawDuration = min(preHitInfo.drawDuration + pitchDuration + distance, preHitInfo.duration)
                preHitInfo.drawDuration = drawDuration
                return currentHighlightInfos
            }
        }
        
        /** 新建 **/
        let stdInfo = hitedInfo
        let drawBeginTime = max(progress - pitchDuration, stdInfo.beginTime)
        let drawDuration = min(pitchDuration, stdInfo.duration)
        let info = Info(beginTime: stdInfo.beginTime,
                        duration: stdInfo.duration,
                        word: stdInfo.word,
                        pitch: stdInfo.pitch,
                        drawBeginTime: drawBeginTime,
                        drawDuration: drawDuration,
                        isLastInLine: false)
        var temp = currentHighlightInfos
        temp.append(info)
        return temp
    }
    
    
    /// 生成DrawInfo
    /// - Returns: (visiableDrawInfos, highlightDrawInfos, currentVisiableInfos, currentHighlightInfos)
    func makeInfos(progress: Int,
                   dataList: [Info],
                   currentHighlightInfos: [Info],
                   defaultPitchCursorX: CGFloat,
                   widthPreMs: CGFloat,
                   canvasViewSize: CGSize,
                   standardPitchStickViewHeight: CGFloat,
                   minPitch: Double,
                   maxPitch: Double) -> ([DrawInfo], [DrawInfo], [Info], [Info]) {
        /// 视图最左边到游标这段距离对应的时长
        let defaultPitchCursorXTime = Int(defaultPitchCursorX / widthPreMs)
        /// 游标到视图最右边对应的时长
        let remainTime = Int((canvasViewSize.width - defaultPitchCursorX) / widthPreMs)
        /// 需要显示音高的开始时间
        let beginTime = max(progress - defaultPitchCursorXTime, 0)
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
        
        return (visiableDrawInfos, highlightDrawInfos, currentVisiableInfos, currentHighlightInfos)
    }
    
    /// 生成最大、最小Pitch值
    /// - Returns: (minPitch, maxPitch)
    func makeMinMaxPitch(dataList: [Info],
                         canvasViewSize: CGSize,
                         standardPitchStickViewHeight: CGFloat) -> (Double, Double) {
        /** set value **/
        let pitchs = dataList.filter({ $0.word != " " }).map({ $0.pitch })
        let maxValue = pitchs.max() ?? 0
        let minValue = pitchs.min() ?? 0
        /// UI上的一个点对于的pitch数量
        let pitchPerPoint = (CGFloat(maxValue) - CGFloat(minValue)) / canvasViewSize.height
        let extend = pitchPerPoint * standardPitchStickViewHeight
        let maxPitch = maxValue + extend
        let minPitch = max(minValue - extend, 0)
        return (minPitch, maxPitch)
    }
    
    /// 获取击中数据
    func getHitedInfo(progress: Int,
                      currentVisiableInfos: [Info],
                      pitchDuration: Int) -> Info? {
        let pitchBeginTime = progress - pitchDuration/2
        return currentVisiableInfos.first { info in
            return pitchBeginTime >= info.drawBeginTime && pitchBeginTime <= info.endTime
        }
    }
    
    /// 查找当前句子的索引
    /// - Parameters:
    /// - Returns: `nil` 表示不合法, 等于 `lineEndTimes.count` 表示最后一句已经结束
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
                     beginTime: Int,
                     endTime: Int) -> [Info] {
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
    
    /// 计算累计分数
    /// - Parameters:
    ///   - indexOfLine: 计算到此index 如：2, 会计算0,1,2的累加值
    func calculatedCumulativeScore(indexOfLine: Int, lineScores: [Int]) -> Int {
        var cumulativeScore = 0
        for (offset, value) in lineScores.enumerated() {
            if offset <= indexOfLine {
                cumulativeScore += value
            }
        }
        return cumulativeScore
    }
}

extension ScoringVM { /** ui 位置 **/
    /// 计算音准线的位置
    func calculateDrawRect(progress: Int,
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
        let x = CGFloat(beginTime - (progress - defaultPitchCursorXTime)) * widthPreMs
        let y = getCenterY(pitch: pitch,
                           canvasViewSize: canvasViewSize,
                           minPitch: minPitch,
                           maxPitch: maxPitch) - (standardPitchStickViewHeight / 2)
        let w = widthPreMs * CGFloat(duration)
        let h = standardPitchStickViewHeight
        let rect = CGRect(x: x, y: y, width: w, height: h)
        return rect
    }
    
    /// 计算y的位置
    func getCenterY(pitch: Double,
                    canvasViewSize: CGSize,
                    minPitch: Double,
                    maxPitch: Double) -> CGFloat {
        let canvasViewHeight = canvasViewSize.height
        
        if pitch <= 0 {
            return canvasViewHeight
        }
        
        if pitch < minPitch {
            return canvasViewHeight
        }
        if pitch > maxPitch {
            return 0
        }
        
        /// 映射成从0开始
        let value = pitch - minPitch
        /// 计算相对偏移
        let distance = (value / (maxPitch - minPitch)) * canvasViewHeight
        let y = canvasViewHeight - distance
        return y
    }
}
