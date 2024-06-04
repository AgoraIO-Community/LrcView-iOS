//
//  ScoringVM.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/11.
//

import Foundation

class ScoringMachine: ScoringMachineProtocol {
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
    var scoreAlgorithm: IScoreAlgorithm = ScoreAlgorithm()
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
    fileprivate var toneScores = [ToneScoreModel]()
    fileprivate var lineScores = [Int]()
    fileprivate var currentIndexOfLine = 0
    fileprivate var lyricData: LyricModel?
    fileprivate var cumulativeScore = 0
    fileprivate var isDragging = false
    fileprivate var voiceChanger = VoicePitchChanger()
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
        Log.debug(text: "progress: \(progress)", tag: "progress")
        queue.async { [weak self] in
            self?._setProgress(progress: progress)
        }
    }
    
    func setPitch(speakerPitch: Double,
                  progressInMs: UInt) {
        queue.async { [weak self] in
            self?._setPitch(pitch: speakerPitch)
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
    
    func getCumulativeScore() -> Int {
        Log.debug(text: "== getCumulativeScore cumulativeScore:\(cumulativeScore)", tag: "drag")
        return cumulativeScore
    }
    
    func setScoreAlgorithm(algorithm: IScoreAlgorithm) {
        self.scoreAlgorithm = algorithm
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
        toneScores = lyricData.lines[0].tones.map({ ToneScoreModel(tone: $0, score: 0) })
        lineScores = .init(repeating: 0, count: lyricData.lines.count)
        handleProgress()
    }
    
    private func _setProgress(progress: UInt) {
        guard !isDragging else { return }
        guard let model = lyricData, model.hasPitch else { return }
        Log.debug(text: "progress: \(progress)", tag: logTag)
        self.progress = progress
        handleProgress()
    }
    
    private func _setPitch(pitch: Double) {
        guard !isDragging else { return }
        guard let model = lyricData, model.hasPitch else { return }
        
        if pitch <= 0 {
            let y = canvasViewSize.height
            let debugInfo = DebugInfo(originalPitch: pitch,
                                      pitch: pitch,
                                      hitedInfo: nil,
                                      progress: progress)
            invokeScoringMachine(didUpdateCursor: y, showAnimation: false, debugInfo: debugInfo)
            return
        }
        
        /** 1.get hitedInfo **/
        guard let hitedInfo = getHitedInfo(progress: progress,
                                           currentVisiableInfos: currentVisiableInfos) else {
            let y = calculatedY(pitch: pitch,
                                viewHeight: canvasViewSize.height,
                                minPitch: minPitch,
                                maxPitch: maxPitch,
                                standardPitchStickViewHeight: standardPitchStickViewHeight)
            
            if y == nil {
                Log.errorText(text: "y is invalid, at getHitedInfo step", tag: logTag)
            }
            let yValue = (y != nil) ? y! : (canvasViewSize.height >= 0 ? canvasViewSize.height : 0)
            let debugInfo = DebugInfo(originalPitch: pitch,
                                      pitch: pitch,
                                      hitedInfo: nil,
                                      progress: progress)
            invokeScoringMachine(didUpdateCursor: yValue, showAnimation: false, debugInfo: debugInfo)
            return
        }
        
        /** 2.voice change **/
        let voicePitch = voiceChanger.handlePitch(stdPitch: hitedInfo.pitch,
                                                  voicePitch: pitch,
                                                  stdMaxPitch: maxPitch)
        Log.debug(text: "pitch: \(pitch) after: \(voicePitch) stdPitch:\(hitedInfo.pitch)", tag: logTag)
        
        /** 3.calculted score **/
        let score = ToneCalculator.calculedScore(voicePitch: voicePitch,
                                                 stdPitch: hitedInfo.pitch,
                                                 scoreLevel: scoreLevel,
                                                 scoreCompensationOffset: scoreCompensationOffset)
        
        /** 4.save tone score  **/
        var hitToneScore = toneScores.first(where: { $0.tone.beginTime == hitedInfo.beginTime })
        if hitToneScore != nil {
            hitToneScore!.addScore(score: score)
        }
        else { /** reresetToneScores while can not find a specific one  **/
            resetToneScores(position: progress)
            hitToneScore = toneScores.first(where: { $0.tone.beginTime == hitedInfo.beginTime })
            if hitToneScore != nil {
                hitToneScore!.addScore(score: score)
            }
            else {
                Log.error(error: "ignore score \(score) progress: \(progress), beginTime: \(hitedInfo.beginTime), endTime: \(hitedInfo.endTime) \(toneScores.map({ "\($0.tone.beginTime)-" }).reduce("", +))", tag: logTag)
            }
        }
        
        /** 5.update HighlightInfos **/
        if score >= hitScoreThreshold * 100 {
            currentHighlightInfos = makeHighlightInfos(progress: progress,
                                                       hitedInfo: hitedInfo,
                                                       currentVisiableInfos: currentVisiableInfos,
                                                       currentHighlightInfos: currentHighlightInfos)
        }
        Log.debug(text: "progress:\(progress) score: \(score) pitch: \(pitch) after: \(voicePitch) stdPitch:\(hitedInfo.pitch)", tag: logTag)
        /** 6.calculated ui info **/
        let showAnimation = score >= hitScoreThreshold * 100
        let y = calculatedY(pitch: voicePitch,
                            viewHeight: canvasViewSize.height,
                            minPitch: minPitch,
                            maxPitch: maxPitch,
                            standardPitchStickViewHeight: standardPitchStickViewHeight)
        if y == nil {
            Log.errorText(text: "y is invalid, at calculated ui info step", tag: logTag)
        }
        let yValue = (y != nil) ? y! : (canvasViewSize.height >= 0 ? canvasViewSize.height : 0)
        let debugInfo = DebugInfo(originalPitch: pitch,
                                  pitch: voicePitch,
                                  hitedInfo: hitedInfo,
                                  progress: progress)
        invokeScoringMachine(didUpdateCursor: yValue, showAnimation: showAnimation, debugInfo: debugInfo)
    }
    
    private func _dragBegain() {
        isDragging = true
    }
    
    private func _dragDidEnd(position: UInt) {
        guard let index = findCurrentIndexOfLine(progress: position, lineEndTimes: lineEndTimes) else {
            return
        }
        
        let indexOfLine = index-1
        cumulativeScore = calculatedCumulativeScore(indexOfLine: indexOfLine, lineScores: lineScores)
        Log.debug(text: "== dragDidEnd cumulativeScore:\(cumulativeScore)", tag: "drag")
        
        if index >= 0, index < lineEndTimes.count, let data = lyricData {
            toneScores = data.lines[index].tones.map({ ToneScoreModel(tone: $0, score: 0) })
            for offset in index..<lineEndTimes.count {
                lineScores[offset] = 0
            }
        }
        
        progress = position
        currentHighlightInfos = []
        isDragging = false
    }
    
    private func resetToneScores(position: UInt) {
        guard let index = findCurrentIndexOfLine(progress: position, lineEndTimes: lineEndTimes) else {
            return
        }
        if index >= 0, index < lineEndTimes.count, let data = lyricData {
            toneScores = data.lines[index].tones.map({ ToneScoreModel(tone: $0, score: 0) })
            for offset in index..<lineEndTimes.count {
                lineScores[offset] = 0
            }
        }
        currentHighlightInfos = []
        Log.info(text: "resetToneScores", tag: logTag)
    }
    
    private func _reset() {
        cumulativeScore = 0
        lyricData = nil
        currentVisiableInfos = []
        currentHighlightInfos = []
        dataList = []
        lineEndTimes = []
        cumulativeScore = 0
        currentIndexOfLine = 0
        lineScores = []
        toneScores = []
        progress = 0
        minPitch = 0
        maxPitch = 0
        voiceChanger.reset()
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
        guard let index = findCurrentIndexOfLine(progress: progress, lineEndTimes: lineEndTimes)  else {
            return
        }
        if currentIndexOfLine != index {
            if index - currentIndexOfLine == 1 { /** 过滤拖拽导致的进度变化,只有正常进度才回调 **/
                didLineEnd(indexOfLineEnd: currentIndexOfLine)
            }
            Log.debug(text: "currentIndexOfLine: \(index) from old: \(currentIndexOfLine)", tag: "drag")
            currentIndexOfLine = index
        }
    }
    
    private func didLineEnd(indexOfLineEnd: Int) {
        guard let data = lyricData, indexOfLineEnd <= data.lines.count else {
            return
        }
        
        let lineScore = scoreAlgorithm.getLineScore(with: toneScores)
        lineScores[indexOfLineEnd] = lineScore
        
        cumulativeScore = calculatedCumulativeScore(indexOfLine: indexOfLineEnd,
                                                    lineScores: lineScores)
        Log.debug(text: "score didLineEnd indexOfLineEnd: \(indexOfLineEnd) \(lineScore) \(lineScores) cumulativeScore:\(cumulativeScore)", tag: logTag)
        invokeScoringMachine(didFinishLineWith: data.lines[indexOfLineEnd],
                             score: lineScore,
                             cumulativeScore: cumulativeScore,
                             lineIndex: indexOfLineEnd,
                             lineCount: data.lines.count)
        let nextIndex = indexOfLineEnd + 1
        if nextIndex < data.lines.count {
            toneScores = data.lines[nextIndex].tones.map({ ToneScoreModel(tone: $0, score: 0) })
        }
    }
}
