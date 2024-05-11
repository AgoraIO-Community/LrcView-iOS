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
    weak var delegate: ScoringMachineDelegate?
    
    fileprivate var progress: UInt = 0
    fileprivate var widthPreMs: CGFloat { movingSpeedFactor / 1000 }
    fileprivate var dataList = [Info]()
    fileprivate var lineEndTimes = [UInt]()
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
    
    func setProgress(progress: UInt) {
//        Log.debug(text: "progress: \(progress)", tag: "progress")
        queue.async { [weak self] in
            self?._setProgress(progress: progress)
        }
    }
    
    func setPitch(speakerPitch: Double,
                  pitchScore: Float,
                  progressInMs: UInt) {
        queue.async { [weak self] in
            self?._setPitch(speakerPitch: UInt8(speakerPitch),
                            progressInMs: progressInMs)
        }
    }
    
    func dragBegain() {
        queue.async { [weak self] in
            self?._dragBegain()
        }
    }
    
    func dragDidEnd(position: UInt) {
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
        let (_, max) = makeMinMaxPitch(dataList: dataList)
        minPitch = 0
        maxPitch = max
        handleProgress()
    }
    
    private func _setProgress(progress: UInt) {
        guard !isDragging else { return }
        guard let model = lyricData, model.hasPitch else { return }
        Log.debug(text: "progress: \(progress)", tag: logTag)
        self.progress = progress
        handleProgress()
    }
    
    /// _setPitch
    /// - Parameters:
    ///   - speakerPitch: 0-100
    private func _setPitch(speakerPitch: UInt8,
                           progressInMs: UInt) {
        guard !isDragging else { return }
        guard let model = lyricData, model.hasPitch else { return }
        
        if speakerPitch <= 0 {
            let y = canvasViewSize.height
            let debugInfo = DebugInfo(originalPitch: -1.0,
                                      pitch: Double(speakerPitch),
                                      hitedInfo: nil,
                                      progress: progressInMs)
            Log.debug(text: "_setPitch[0] porgress:\(progressInMs) speakerPitch:\(speakerPitch)", tag: logTag)
            invokeScoringMachine(didUpdateCursor: y, showAnimation: false, debugInfo: debugInfo)
            return
        }
        
        /** 1.get hitedInfo **/
        guard let hitedInfo = getHitedInfo(progress: progressInMs,
                                           currentVisiableInfos: currentVisiableInfos) else {
            let debugInfo = DebugInfo(originalPitch: -1,
                                      pitch: Double(speakerPitch),
                                      hitedInfo: nil,
                                      progress: progressInMs)
            Log.debug(text: "_setPitch[1] porgress:\(progressInMs) speakerPitch:\(speakerPitch)", tag: logTag)
            return
        }
        
        var actualspeakerPitch: Double = 0
        if speakerPitch <= 5 {
            if speakerPitch == 3 {
                actualspeakerPitch = hitedInfo.pitch
            }
            else if speakerPitch < 3 {
                actualspeakerPitch = hitedInfo.pitch - Double(speakerPitch)
            }
            else {
                actualspeakerPitch = hitedInfo.pitch + Double(speakerPitch)
            }
        }
        else {
            actualspeakerPitch = Double(speakerPitch)
        }
        
        let showAnimation = speakerPitch <= 5
        
        /** 2.update HighlightInfos **/
        if showAnimation {
            currentHighlightInfos = makeHighlightInfos(progress: progressInMs,
                                                       hitedInfo: hitedInfo,
                                                       currentVisiableInfos: currentVisiableInfos,
                                                       currentHighlightInfos: currentHighlightInfos)
        }
        
        /** 3.calculated ui info **/
        
        if actualspeakerPitch > maxPitch {
            Log.errorText(text: "actualspeakerPitch > maxPitch, \(actualspeakerPitch)", tag: logTag)
        }
        
        let y = calculatedY(pitch: showAnimation ? hitedInfo.pitch : actualspeakerPitch,
                            viewHeight: canvasViewSize.height,
                            minPitch: minPitch,
                            maxPitch: maxPitch,
                            standardPitchStickViewHeight: standardPitchStickViewHeight)
        if y == nil {
            Log.errorText(text: "y is invalid, at calculated ui info step", tag: logTag)
        }
        let yValue = (y != nil) ? y! : (canvasViewSize.height >= 0 ? canvasViewSize.height : 0)
        let debugInfo = DebugInfo(originalPitch: hitedInfo.pitch,
                                  pitch: Double(speakerPitch),
                                  hitedInfo: hitedInfo,
                                  progress: progressInMs)
        Log.debug(text: "_setPitch[2] porgress:\(progressInMs) speakerPitch:\(speakerPitch)", tag: logTag)
        invokeScoringMachine(didUpdateCursor: yValue, showAnimation: showAnimation, debugInfo: debugInfo)
    }
    
    private func _dragBegain() {
        isDragging = true
    }
    
    private func _dragDidEnd(position: UInt) {
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
