//
//  ScoringMachine+DataHandle.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/2/2.
//

import Foundation

extension ScoringMachine {
    /// 创建Scoring内部数据
    ///   - shouldFixTime: 是否要修复时间异常问题
    ///   - return: (行结束时间, 字模型)
    static func createData(data: LyricModel, shouldFixTime: Bool = true) -> ([UInt], [Info]) {
        var array = [Info]()
        var lineEndTimes = [UInt]()
        var preEndTime: UInt = 0
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
    
    func makeHighlightInfos(progress: UInt,
                            hitedInfo: Info,
                            currentVisiableInfos: [Info],
                            currentHighlightInfos: [Info]) -> [Info] {
        let pitchDuration = 50
        if let preHitInfo = currentHighlightInfos.last, preHitInfo.beginTime == hitedInfo.beginTime { /** 判断是否需要追加 **/
            let newDrawBeginTime = max(progress, preHitInfo.beginTime)
            let distance = abs(Int(newDrawBeginTime) - Int(preHitInfo.drawEndTime))
            if distance < pitchDuration { /** 追加 **/
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
                        drawDuration: drawDuration,
                        isLastInLine: false)
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
