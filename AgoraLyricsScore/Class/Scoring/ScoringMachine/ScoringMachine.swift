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
    var scoreAlgorithm: IScoreAlgorithm = ScoreAlgorithm()
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
    fileprivate var pitchScores = [PitchScoreModel]()
    fileprivate var currentIndexOfLine = 0
    fileprivate var lyricData: LyricModel?
    fileprivate var pitchData: PitchModel?
    fileprivate var cumulativeScore = 0
    fileprivate var voiceChanger = VoicePitchChanger()
    fileprivate let queue = DispatchQueue(label: "ScoringMachine")
    fileprivate let logTag = "ScoringMachine"
    
    // MARK: - Internal
    
    func setLyricData(data: LyricModel) {}
    
    func setPitchData(data: PitchModel?) {
        guard let pitchData = data else { return }
        guard let size = delegate?.sizeOfCanvasView(self) else { fatalError("sizeOfCanvasView has not been implemented") }
        queue.async { [weak self] in
            self?._setPitchData(pitchData: pitchData, size: size)
        }
    }
    
    func setProgress(progress: Int) {
        Log.debug(text: "progress: \(progress)", tag: "progress")
        queue.async { [weak self] in
            Log.debug(text: "==progress: \(progress)", tag: "progress")
            self?._setProgress(progress: progress)
        }
    }
    
    func setPitch(pitch: Double) {
        queue.async { [weak self] in
            self?._setPitch(pitch: pitch)
        }
    }
    
    func dragBegain() {
        
    }
    
    func dragDidEnd(position: Int) {
        
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
    
    private func _setPitchData(pitchData: PitchModel, size: CGSize) {
        canvasViewSize = size
        self.pitchData = pitchData
        let infos = ScoringMachine.createData(data: pitchData)
        dataList = infos
        let (min, max) = makeMinMaxPitch(dataList: dataList)
        minPitch = min
        maxPitch = max
        pitchScores = pitchData.items.map({ .init(pitchItem: $0, score: 0) })
        handleProgress()
    }
    
    private func _setProgress(progress: Int) {
        self.progress = progress
        handleProgress()
    }
    
    private func _setPitch(pitch: Double) {
        guard pitchData != nil else { return } /** setLyricData 后执行 **/
        
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
            let debugInfo = DebugInfo(originalPitch: pitch,
                                      pitch: pitch,
                                      hitedInfo: nil,
                                      progress: progress)
            invokeScoringMachine(didUpdateCursor: y, showAnimation: false, debugInfo: debugInfo)
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
        if let hitPitchScore = pitchScores.first(where: { $0.pitchItem.beginTime == hitedInfo.beginTime }) {
            hitPitchScore.addScore(score: score)
        }
        else {
            Log.error(error: "ignore score \(score) progress: \(progress), beginTime: \(hitedInfo.beginTime), endTime: \(hitedInfo.endTime) \(pitchScores.map({ "\($0.pitchItem.beginTime)-" }).reduce("", +))", tag: logTag)
        }
        
        /** 5.update HighlightInfos **/
        if score >= hitScoreThreshold * 100 {
            currentHighlightInfos = makeHighlightInfos(progress: progress,
                                                       hitedInfo: hitedInfo,
                                                       currentVisiableInfos: currentVisiableInfos,
                                                       currentHighlightInfos: currentHighlightInfos)
        }
        Log.debug(text: "score: \(score)", tag: logTag)
        /** 6.calculated ui info **/
        let showAnimation = score >= hitScoreThreshold * 100
        let y = calculatedY(pitch: voicePitch,
                            viewHeight: canvasViewSize.height,
                            minPitch: minPitch,
                            maxPitch: maxPitch,
                            standardPitchStickViewHeight: standardPitchStickViewHeight)
        
        let debugInfo = DebugInfo(originalPitch: pitch,
                                  pitch: voicePitch,
                                  hitedInfo: hitedInfo,
                                  progress: progress)
        invokeScoringMachine(didUpdateCursor: y, showAnimation: showAnimation, debugInfo: debugInfo)
        cumulativeScore = Int(pitchScores.map({ $0.score }).reduce(0, +))
        invokeScoringMachine(didFinishToneWith: pitchScores, cumulativeScore: cumulativeScore)
    }
    
    private func _reset() {
        cumulativeScore = 0
        lyricData = nil
        pitchData = nil
        currentVisiableInfos = []
        currentHighlightInfos = []
        dataList = []
        lineEndTimes = []
        cumulativeScore = 0
        currentIndexOfLine = 0
        pitchScores = []
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
    }
}
