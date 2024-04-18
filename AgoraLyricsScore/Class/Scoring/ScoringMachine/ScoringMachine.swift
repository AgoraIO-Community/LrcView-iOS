//
//  ScoringVM.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation
class ScoringMachine {
    /// 游标的起始位置
    var defaultPitchCursorX: CGFloat = 100
    /// 音准线的高度
    var standardPitchStickViewHeight: CGFloat = 3
    /// 音准线的基准因子
    var movingSpeedFactor: CGFloat = 120
    /// 打分容忍度 范围：0-1
    var hitScoreThreshold: Float = 0.7
    var scoreLevel = 10
    var scoreCompensationOffset = 0
    weak var delegate: ScoringMachineDelegate?
    
    fileprivate var progress: Int = 0
    fileprivate var widthPreMs: CGFloat { movingSpeedFactor / 1000 }
    fileprivate var dataList = [Info]()
    fileprivate var lineEndTimes = [Int]()
    fileprivate var currentVisiableInfos = [Info]()
    fileprivate var currentHighlightInfos = [Info]()
    fileprivate var maxPitch: Double = 0
    fileprivate var minPitch: Double = 0
    
    fileprivate var canvasViewSize: CGSize = .zero
    fileprivate var lyricData: LyricModel?
    fileprivate var isDragging = false
    fileprivate let queue = DispatchQueue(label: "ScoringMachine")
    let logTag = "ScoringMachine"
    
    // MARK: - Internal
    
    func setLyricData(data: LyricModel?) {
        guard let lyricData = data else { return }
        guard let size = delegate?.sizeOfCanvasView(self) else { fatalError("sizeOfCanvasView has not been implemented") }
        queue.async { [weak self] in
            self?._setLyricData(lyricData: lyricData, size: size)
        }
    }
    
    func setProgress(progress: Int) {
//        Log.debug(text: "progress: \(progress)", tag: "progress")
        queue.async { [weak self] in
            self?._setProgress(progress: progress)
        }
    }
    
    func setPitch(speakerPitch: Double,
                  pitchScore: Float,
                  progressInMs: Int) {
        queue.async { [weak self] in
            self?._setPitch(speakerPitch: speakerPitch,
                            pitchScore: pitchScore,
                            progressInMs: progressInMs)
        }
    }
    
    func dragBegain() {
        queue.async { [weak self] in
            self?._dragBegain()
        }
    }
    
    func dragDidEnd(position: Int) {
        queue.async { [weak self] in
            self?._dragDidEnd(position: position)
        }
    }
    
    func reset() {
        queue.async { [weak self] in
            self?._reset()
        }
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    // MARK: - Private
    
    private func _setLyricData(lyricData: LyricModel, size: CGSize) {
        canvasViewSize = size
        self.lyricData = lyricData
        let (lineEnds, infos) = ScoringMachine.createData(data: lyricData)
        dataList = infos
        lineEndTimes = lineEnds
        let (min, max) = makeMinMaxPitch(dataList: dataList)
        minPitch = min
        maxPitch = max
        handleProgress()
    }
    
    private func _setProgress(progress: Int) {
        guard !isDragging else { return }
        guard let model = lyricData, model.hasPitch else { return }
        Log.debug(text: "progress: \(progress)", tag: logTag)
        self.progress = progress
        handleProgress()
    }
    
    private func _setPitch(speakerPitch: Double,
                           pitchScore: Float,
                           progressInMs: Int) {
        guard !isDragging else { return }
        guard let model = lyricData, model.hasPitch else { return }
        
        if speakerPitch <= 0 {
            let y = canvasViewSize.height
            let debugInfo = DebugInfo(originalPitch: speakerPitch,
                                      pitch: speakerPitch,
                                      hitedInfo: nil,
                                      progress: progressInMs)
            Log.debug(text: "_setPitch[0] porgress:\(progressInMs) speakerPitch:\(speakerPitch) score:\(pitchScore)", tag: logTag)
            invokeScoringMachine(didUpdateCursor: y, showAnimation: false, debugInfo: debugInfo)
            return
        }
        
        /** 1.get hitedInfo **/
        guard let hitedInfo = getHitedInfo(progress: progressInMs,
                                           currentVisiableInfos: currentVisiableInfos) else {
            let y = calculatedY(pitch: speakerPitch,
                                viewHeight: canvasViewSize.height,
                                minPitch: minPitch,
                                maxPitch: maxPitch,
                                standardPitchStickViewHeight: standardPitchStickViewHeight)
            
            if y == nil {
                Log.errorText(text: "y is invalid, at getHitedInfo step", tag: logTag)
            }
            let yValue = (y != nil) ? y! : (canvasViewSize.height >= 0 ? canvasViewSize.height : 0)
            let debugInfo = DebugInfo(originalPitch: -1,
                                      pitch: speakerPitch,
                                      hitedInfo: nil,
                                      progress: progressInMs)
            Log.debug(text: "_setPitch[1] porgress:\(progressInMs) speakerPitch:\(speakerPitch) score:\(pitchScore)", tag: logTag)
            invokeScoringMachine(didUpdateCursor: yValue,
                                 showAnimation: false,
                                 debugInfo: debugInfo)
            return
        }
        
        let score = pitchScore
        
        /** 2.update HighlightInfos **/
        if score >= hitScoreThreshold * 100 {
            currentHighlightInfos = makeHighlightInfos(progress: progressInMs,
                                                       hitedInfo: hitedInfo,
                                                       currentVisiableInfos: currentVisiableInfos,
                                                       currentHighlightInfos: currentHighlightInfos)
        }
        
        /** 3.calculated ui info **/
        let showAnimation = score >= hitScoreThreshold * 100
        let y = calculatedY(pitch: showAnimation ? hitedInfo.pitch : speakerPitch,
                            viewHeight: canvasViewSize.height,
                            minPitch: minPitch,
                            maxPitch: maxPitch,
                            standardPitchStickViewHeight: standardPitchStickViewHeight)
        if y == nil {
            Log.errorText(text: "y is invalid, at calculated ui info step", tag: logTag)
        }
        let yValue = (y != nil) ? y! : (canvasViewSize.height >= 0 ? canvasViewSize.height : 0)
        let debugInfo = DebugInfo(originalPitch: hitedInfo.pitch,
                                  pitch: speakerPitch,
                                  hitedInfo: hitedInfo,
                                  progress: progressInMs)
        Log.debug(text: "_setPitch[2] porgress:\(progressInMs) speakerPitch:\(speakerPitch) score:\(pitchScore)", tag: logTag)
        invokeScoringMachine(didUpdateCursor: yValue, showAnimation: showAnimation, debugInfo: debugInfo)
    }
    
    private func _dragBegain() {
        isDragging = true
    }
    
    private func _dragDidEnd(position: Int) {
        progress = position
        currentHighlightInfos = []
        isDragging = false
    }
    
    private func _reset() {
        lyricData = nil
        currentVisiableInfos = []
        currentHighlightInfos = []
        dataList = []
        progress = 0
        minPitch = 0
        maxPitch = 0
    }
    
    private func handleProgress() {
        /// 计算需要绘制的数据
        let (visiableDrawInfos, highlightDrawInfos, visiableInfos, highlightInfos) = makeInfos(progress: progress,
                                                                                               dataList: dataList,
                                                                                               currentHighlightInfos: currentHighlightInfos,
                                                                                               defaultPitchCursorX: defaultPitchCursorX,
                                                                                               widthPreMs: widthPreMs,
                                                                                               canvasViewSize: canvasViewSize,
                                                                                               standardPitchStickViewHeight: standardPitchStickViewHeight,
                                                                                               minPitch: minPitch,
                                                                                               maxPitch: maxPitch)
        currentVisiableInfos = visiableInfos
        currentHighlightInfos = highlightInfos
        invokeScoringMachine(didUpdateDraw: visiableDrawInfos, highlightInfos: highlightDrawInfos)
    }
}
