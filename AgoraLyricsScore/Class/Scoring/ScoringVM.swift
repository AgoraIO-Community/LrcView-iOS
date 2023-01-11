//
//  ScoringVM.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

class ScoringVM {
    var progress: Int = 0 { didSet { updateProgress() } }
    /// 游标的起始位置
    var defaultPitchCursorX: CGFloat = 100
    /// 音准线的高度
    var standardPitchStickViewHeight: CGFloat = 3
    /// 音准线的基准因子
    var movingSpeedFactor: CGFloat = 120
    /// 打分容忍度 范围：0-1
    var hitScoreThreshold: Float = 0.7
    
    weak var delegate: ScoringVMDelegate?
    
    fileprivate var widthPreMs: CGFloat { movingSpeedFactor / 1000 }
    fileprivate var dataList = [Info]()
    fileprivate var currentVisiableInfos = [Info]()
    fileprivate var currentHighlightInfos = [Info]()
    fileprivate var maxPitch: Double = 0
    fileprivate var minPitch: Double = 0
    fileprivate var scoreLevel = 0
    fileprivate var scoreCompensationOffset = 0
    /// 产生pitch花费的时间 ms
    fileprivate let pitchDuration = 50
    fileprivate var canvasViewSize: CGSize = .zero
    fileprivate let queue = DispatchQueue(label: "ScoringVM.queue")
    
    func setLyricData(data: LyricModel?) {
        guard let lyricData = data else { return }
        guard let size = delegate?.sizeOfCanvasView(self) else { fatalError("sizeOfCanvasView has not been implemented") }
        canvasViewSize = size
        dataList = createData(data: lyricData)
        let (min, max) = makeMinMaxPitch()
        minPitch = min
        maxPitch = max
        updateProgress()
    }
    
    func reset() {
        progress = 0
    }
    
    private func updateProgress() {
        let (visiableDrawInfos, highlightDrawInfos) = makeInfos()
        invokeScoringVM(didUpdateDraw: visiableDrawInfos, highlightInfos: highlightDrawInfos)
    }
    
    func setPitch(pitch: Double) {
        let y = getCenterY(pitch: pitch)
        var showAnimation = false
        if pitch > 0 {
            let info = updateHighlightInfos(progress: progress,
                                            pitch: pitch,
                                            currentVisiableInfos: currentVisiableInfos)
            showAnimation = info != nil
        }
        invokeScoringVM(didUpdateCursor: y, showAnimation: showAnimation)
    }
}

extension ScoringVM { /** Data handle **/
    private func createData(data: LyricModel) -> [Info] {
        var array = [Info]()
        for line in data.lines {
            for tone in line.tones {
                let info = Info(beginTime: tone.beginTime,
                                duration: tone.duration,
                                word: tone.word,
                                pitch: tone.pitch,
                                drawBeginTime: tone.beginTime,
                                drawDuration: tone.duration)
                array.append(info)
            }
        }
        return array
    }
    
    /// 生成DrawInfo
    /// - Returns: (visiableDrawInfos, highlightDrawInfos)
    private func makeInfos() -> ([DrawInfo], [DrawInfo]) {
        /// 视图最左边到游标这段距离对应的时长
        let defaultPitchCursorXTime = Int(defaultPitchCursorX / widthPreMs)
        /// 游标到视图最右边对应的时长
        let remainTime = Int((canvasViewSize.width - defaultPitchCursorX) / widthPreMs)
        /// 需要显示音高的开始时间
        let beginTime = max(progress - defaultPitchCursorXTime, 0)
        /// 需要显示音高的结束时间
        let endTime = progress + remainTime
        
        currentVisiableInfos = filterInfos(infos: dataList,
                                           beginTime: beginTime,
                                           endTime: endTime)
        currentHighlightInfos = filterInfos(infos: currentHighlightInfos,
                                            beginTime: beginTime,
                                            endTime: endTime)
        
        var visiableDrawInfos = [DrawInfo]()
        for info in currentVisiableInfos {
            let rect = calculateDrawRect(info: info)
            let drawInfo = DrawInfo(rect: rect)
            visiableDrawInfos.append(drawInfo)
        }
        
        var highlightDrawInfos = [DrawInfo]()
        for info in currentHighlightInfos {
            let rect = calculateDrawRect(info: info)
            let drawInfo = DrawInfo(rect: rect)
            highlightDrawInfos.append(drawInfo)
        }
        
        return (visiableDrawInfos, highlightDrawInfos)
    }
    
    /// 生成最大、最小Pitch值
    /// - Returns: (minPitch, maxPitch)
    func makeMinMaxPitch() -> (Double, Double) {
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
    
    /// 更新高亮数据
    /// - Returns: 返回击中的数据
    private func updateHighlightInfos(progress: Int,
                                      pitch: Double,
                                      currentVisiableInfos: [Info]) -> Info? {
        if let preInfo = currentHighlightInfos.last,
           let preHitInfo = getHitedInfo(progress: progress, currentVisiableInfos: [preInfo])  { /** 判断是否可追加 **/
            let score = ToneCalculator.calculedScore(voicePitch: pitch,
                                                     stdPitch: preInfo.pitch,
                                                     minPitch: minPitch,
                                                     maxPitch: maxPitch,
                                                     scoreLevel: scoreLevel,
                                                     scoreCompensationOffset: scoreCompensationOffset)
            if score >= hitScoreThreshold * 100 {
                let newDrawBeginTime = max(progress - pitchDuration, preHitInfo.beginTime)
                let distance = newDrawBeginTime - preHitInfo.drawEndTime
                if distance < pitchDuration { /** 追加 **/
                    let drawDuration = min(preHitInfo.drawDuration + pitchDuration + distance, preHitInfo.duration)
                    preHitInfo.drawDuration = drawDuration
                    return preHitInfo
                }
            }
        }
        
        if let stdInfo = getHitedInfo(progress: progress, currentVisiableInfos: currentVisiableInfos) { /** 新建 **/
            let score = ToneCalculator.calculedScore(voicePitch: pitch,
                                                     stdPitch: stdInfo.pitch,
                                                     minPitch: minPitch,
                                                     maxPitch: maxPitch,
                                                     scoreLevel: scoreLevel,
                                                     scoreCompensationOffset: scoreCompensationOffset)
            if score >= hitScoreThreshold * 100 {
                let drawBeginTime = max(progress - pitchDuration, stdInfo.beginTime)
                let drawDuration = min(pitchDuration, stdInfo.duration)
                let info = Info(beginTime: stdInfo.beginTime,
                                duration: stdInfo.duration,
                                word: stdInfo.word,
                                pitch: stdInfo.pitch,
                                drawBeginTime: drawBeginTime,
                                drawDuration: drawDuration)
                currentHighlightInfos.append(info)
                return info
            }
        }
        
        return nil
    }
    
    /// 获取击中数据
    private func getHitedInfo(progress: Int, currentVisiableInfos: [Info]) -> Info? {
        let pitchBeginTime = progress - pitchDuration/2
        return currentVisiableInfos.first { info in
            return pitchBeginTime >= info.drawBeginTime && pitchBeginTime <= info.endTime
        }
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
    
    /// 计算音准线的位置
    func calculateDrawRect(info: Info) -> CGRect {
        let beginTime = info.drawBeginTime
        let duration = info.drawDuration
        let pitch = info.pitch
        
        /// 视图最左边到游标这段距离对应的时长
        let defaultPitchCursorXTime = Int(defaultPitchCursorX / widthPreMs)
        let x = CGFloat(beginTime - (progress - defaultPitchCursorXTime)) * widthPreMs
        let y = getCenterY(pitch: pitch) - (standardPitchStickViewHeight / 2)
        let w = widthPreMs * CGFloat(duration)
        let h = standardPitchStickViewHeight
        let rect = CGRect(x: x, y: y, width: w, height: h)
        return rect
    }
    
    /// 计算y的位置
    private func getCenterY(pitch: Double) -> CGFloat {
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
