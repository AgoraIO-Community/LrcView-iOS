//
//  ScoringMachineEx.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2024/6/3.
//

import Foundation
class ScoringMachineEx: ScoringMachineProtocol {
    /// 游标的起始位置
    var defaultPitchCursorX: CGFloat = 100
    /// 音准线的高度
    var standardPitchStickViewHeight: CGFloat = 3
    /// 音准线的基准因子
    var movingSpeedFactor: CGFloat = 120
    /// 打分容忍度 范围：0-1
    var hitScoreThreshold: Float = 0.7
    /// 是否开启“拖腔字”的优化
    var isSustainedPitchOptimizationEnabled: Bool = false
    weak var delegate: ScoringMachineDelegate?
    
    /// no use
    var scoreLevel: Int = 0
    var scoreCompensationOffset: Int = 0
    var scoreAlgorithm: IScoreAlgorithm = ScoreAlgorithm()
    
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
    fileprivate var pitchIsZeroCount = 0
    fileprivate var lastNoZeroPitchReplayInfo: PitchReplayInfo?
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
                  progressInMs: UInt,
                  score: UInt) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self._setPitchPreProcess(speakerPitch: speakerPitch,
                                     progressInMs: progressInMs,
                                     score: score)
            
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
    
    func getCumulativeScore() -> Int { 0 }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    // MARK: - Private
    
    private func _setLyricData(lyricData: LyricModel, size: CGSize) {
        canvasViewSize = size
        self.lyricData = lyricData
        let (lineEnds, infos) = lyricData.pitchDatas.isEmpty ? ScoringMachine.createData(data: lyricData) : ScoringMachineEx.createData(data: lyricData)
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
    
    private func _setPitchPreProcess(speakerPitch: Double,
                                     progressInMs: UInt,
                                     score: UInt) {
        if !isSustainedPitchOptimizationEnabled {
            _setPitchPreProcess1(speakerPitch: speakerPitch,
                                 progressInMs: progressInMs,
                                 score: score)
            return
        }
        
        _setPitchPreProcess2(speakerPitch: speakerPitch,
                             progressInMs: progressInMs,
                             score: score)
    }
    
    private func _setPitchPreProcess1(speakerPitch: Double,
                                     progressInMs: UInt,
                                     score: UInt) {
        if speakerPitch == 0 {
            pitchIsZeroCount += 1
        }
        else {
            pitchIsZeroCount = 0
        }
        if speakerPitch > 0 || pitchIsZeroCount >= 10 { /** 过滤10个0的情况* **/
            pitchIsZeroCount = 0
            let _ = _setPitch(speakerPitch: speakerPitch,
                              progressInMs: progressInMs,
                              score: score,
                              ignoreScoreAccumulation: false)
        }
    }
    
    private func _setPitchPreProcess2(speakerPitch: Double,
                                     progressInMs: UInt,
                                      score: UInt) {
        /** using Sustained Pitch Optimization **/
        
        if speakerPitch == 0 {
            pitchIsZeroCount += 1
            if pitchIsZeroCount >= 10 { /** no need to replay **/
                let _ = self._setPitch(speakerPitch: speakerPitch,
                                       progressInMs: progressInMs,
                                       score: score,
                                       ignoreScoreAccumulation: false)
                return
            }
            
            if let replayInfo = lastNoZeroPitchReplayInfo {
                if progressInMs >= replayInfo.hitedBeginTime, progressInMs < replayInfo.hitedEndTime {
                    let _ = self._setPitch(speakerPitch: replayInfo.speakerPitch,
                                           progressInMs: progressInMs,
                                           score: replayInfo.score,
                                           ignoreScoreAccumulation: true)
                    return
                }
            }
            
            return
        }
        
        pitchIsZeroCount = 0
        /// can hit
        if let hitedInfo = self._setPitch(speakerPitch: speakerPitch,
                                          progressInMs: progressInMs,
                                          score: score,
                                          ignoreScoreAccumulation: false) {
            lastNoZeroPitchReplayInfo = PitchReplayInfo(speakerPitch: speakerPitch,
                                                        progressInMs: progressInMs,
                                                        hitedBeginTime: hitedInfo.beginTime,
                                                        hitedEndTime: hitedInfo.endTime,
                                                        score: score)
            return
        }
        
        /// can not hit
        lastNoZeroPitchReplayInfo = nil
    }
    
    var lastProgressInMs: Int = 0
    
    /// _setPitch
    /// - Parameters:
    ///   - speakerPitch: 0-100
    private func _setPitch(speakerPitch: Double,
                           progressInMs: UInt,
                           score: UInt,
                           ignoreScoreAccumulation: Bool) -> Info? {
        let progressGap = Int(progressInMs) - lastProgressInMs
        lastProgressInMs = Int(progressInMs)
        guard !isDragging else { return nil  }
        guard let model = lyricData, model.hasPitch else { return nil }
        
        if speakerPitch <= 0 {
            let y = canvasViewSize.height
            let debugInfo = DebugInfo(originalPitch: -1.0,
                                      pitch: speakerPitch,
                                      hitedInfo: nil,
                                      progress: progressInMs,
                                      score: score,
                                      ignoreScoreAccumulation: ignoreScoreAccumulation)
            Log.debug(text: "_setPitch[0] porgress:\(progressInMs) speakerPitch:\(speakerPitch) progressGap:\(progressGap)", tag: logTag)
            ScoringMachineEventInvoker.invokeScoringMachine(scoringMachine: self,
                                                            didUpdateCursor: y,
                                                            showAnimation: false,
                                                            debugInfo: debugInfo)
            return nil
        }
        
        /** 1.get hitedInfo **/
        guard let hitedInfo = getHitedInfo(progress: progressInMs,
                                           currentVisiableInfos: currentVisiableInfos) else {
            Log.debug(text: "_setPitch[1] progressInMs:\(progressInMs) speakerPitch:\(speakerPitch) progress:\(progress) progressGap:\(progressGap)", tag: logTag)
            return nil
        }
        
        if ignoreScoreAccumulation {
            Log.debug(text: "only update ui", tag: logTag)
        }
        
        /// 着色、动画开启与否
        var showAnimation = false
        if model.pitchDatas.isEmpty {
            showAnimation = score >= UInt(hitScoreThreshold * 100)
        }
        else {
            showAnimation = abs(Int32(speakerPitch) - Int32(hitedInfo.pitch)) <= 5
        }
        
        /** 2.update HighlightInfos **/
        if showAnimation {
            currentHighlightInfos = makeHighlightInfos(progress: progressInMs,
                                                       hitedInfo: hitedInfo,
                                                       currentVisiableInfos: currentVisiableInfos,
                                                       currentHighlightInfos: currentHighlightInfos)
        }
        
        /** 3.calculated ui info **/
        
        if speakerPitch > maxPitch {
            Log.errorText(text: "speakerPitch > maxPitch, \(speakerPitch)", tag: logTag)
        }
        
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
                                  progress: progressInMs,
                                  score: score,
                                  ignoreScoreAccumulation: ignoreScoreAccumulation)
        Log.debug(text: "_setPitch[2] porgress:\(progressInMs) speakerPitch:\(speakerPitch) yValue:\(yValue) progressGap:\(progressGap)", tag: logTag)
        ScoringMachineEventInvoker.invokeScoringMachine(scoringMachine: self,
                                                        didUpdateCursor: yValue,
                                                        showAnimation: showAnimation,
                                                        debugInfo: debugInfo)
        
        return hitedInfo
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
        lastNoZeroPitchReplayInfo = nil
        pitchIsZeroCount = 0
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
        ScoringMachineEventInvoker.invokeScoringMachine(scoringMachine: self,
                                                        didUpdateDraw: visiableDrawInfos,
                                                        highlightInfos: highlightDrawInfos)
    }
}
