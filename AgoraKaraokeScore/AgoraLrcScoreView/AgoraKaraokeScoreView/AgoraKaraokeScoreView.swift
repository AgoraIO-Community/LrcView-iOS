//
//  AgoraKaraokeScoreView.swift
//  lineTTTT
//
//  Created by zhaoyongqiang on 2021/12/8.
//  Copyright © 2021 km. All rights reserved.
//

import UIKit

@objc(AgoraKaraokeScoreDelegate)
public
protocol AgoraKaraokeScoreDelegate {
    /// 分数实时回调
    /// score: 每次增加的分数
    /// cumulativeScore: 累加分数
    /// totalScore: 总分
    @objc optional func agoraKaraokeScore(score: Double, cumulativeScore: Double, totalScore: Double)
    
    /// 是否需要显示动画
    /// - Parameter showAnimation: `true`表示需要显示动画，`false`表示不需要显示动画
    @objc optional func agoraKaraokeViewShouldUpdateUI(showAnimation: Bool)
    
    @objc optional func debugText(text: String)
}

@objcMembers
public class AgoraKaraokeScoreView: UIView {
    // MARK: 公开属性
    
    public weak var delegate: AgoraKaraokeScoreDelegate?
    
    var lrcSentence: [AgoraMiguLrcSentence]? {
        didSet {
            self.totalScore = Double(lrcSentence?.count ?? 0) * (scoreConfig?.lineCalcuScore ?? 100)
        }
    }
    
    /// 线的配置
    private var _scoreConfig: AgoraScoreItemConfigModel = .init() {
        didSet {
            updateUI()
        }
    }
    
    public var scoreConfig: AgoraScoreItemConfigModel? {
        set {
            _scoreConfig = newValue ?? AgoraScoreItemConfigModel()
        }
        get {
            return _scoreConfig
        }
    }
    
    // MARK: 私有
    
    private var dataArray: [AgoraScoreItemModel]? {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = .zero
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.footerReferenceSize = .zero
        flowLayout.headerReferenceSize = .zero
        return flowLayout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AgoraKaraokeScoreCell.self, forCellWithReuseIdentifier: "AgoraKaraokeScoreCell")
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    @objc public lazy var separatorVerticalLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemPink
        return view
    }()
    
    private lazy var separatorTopLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemPink
        return view
    }()
    
    private lazy var separatorBottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemPink
        return view
    }()
    
    @objc public lazy var cursorView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var emitterView = AgoraEmitterView()
    private lazy var triangleView = AgoraTriangleView()
    
    private var animationDuration: TimeInterval = 0.25
    private var status: AgoraKaraokeScoreStatus = .`init`
    private var verticalLineLeadingCons: NSLayoutConstraint?
    private var cursorTopCons: NSLayoutConstraint?
    private var currentTime: TimeInterval = 0
    private var totalTime: TimeInterval = 0
    private var isDrawingCell: Bool = false {
        didSet {
            updateDraw()
        }
    }
    
    private var totalScore: Double = 0
    private var currentScore: Double = 50
    private var scoreArray: [ToneScore] = []
    /// 每句的结束时间
    private var lineEndTimes = [Double]()
    /// 上一句的索引
    private var lastLineIndex = -1
    let logTag = "AgoraKaraokeScoreView"
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reset() {
        Log.info(text: "reset", tag: logTag)
        lastLineIndex = -1
        currentScore = _scoreConfig.defaultScore
        lineEndTimes = []
        currentTime = 0
        totalTime = 0
        scoreArray.removeAll()
        dataArray = []
        collectionView.reloadData()
        voicePitchChanger?.reset()
    }
    
    func setTotalTime(totalTime: TimeInterval) {
        createScoreData(data: lrcSentence)
        self.totalTime = totalTime
    }
    
    var startPrintCount = 0
    func start(currentTime: TimeInterval) {
        self.currentTime = currentTime
        guard currentTime > 0, totalTime > 0 else { return }
        if self.totalTime != totalTime {
            reset()
            setTotalTime(totalTime: totalTime)
        }
        emitterView.setupEmitterPoint(point: cursorView.center)
        let contentWidth = collectionView.contentSize.width - frame.width
        let rate = currentTime / totalTime
        let pointX = contentWidth * rate
        
        startPrintCount += 1
        if startPrintCount > 4 * 100 { /** 4 * 100 * 10ms = 4s打印一次 **/
            startPrintCount = 0
            Log.info(text: "start pointX:\(pointX) rate: \(rate) currentTime: \(currentTime) totalTime: \(totalTime) contentWidth: \(contentWidth)", tag: logTag)
        }
        
        collectionView.setContentOffset(CGPoint(x: pointX, y: 0),
                                        animated: false)
        calculedLineEnd(currentTime: currentTime * 1000)
    }
    
    func scrollToTop(animation: Bool = false) {
        guard !collectionView.visibleCells.isEmpty else { return }
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: animation)
    }
    
    /// 计算句子结束 ms
    func calculedLineEnd(currentTime: TimeInterval) {
        if let index = findIndexOfEndLine(progress: currentTime, lineEndTims: lineEndTimes), lastLineIndex != index {
            Log.info(text: "findIndexOfEndLine \(index) currentTime:\(currentTime)", tag: logTag)
            lastLineIndex = index
            lyricsLineEnds(lineIndex: lastLineIndex)
        }
    }
    
    /// 查找句子结束位置
    private func findIndexOfEndLine(progress: TimeInterval, lineEndTims: [Double]) -> Int? {
        if lineEndTims.isEmpty {
            return nil
        }
        
        if progress >= lineEndTims.last! { /** 处理最后一个 **/
            return lineEndTims.count - 1
        }
        
        var index: Int?
        for item in lineEndTims.enumerated() {
            if item.element == progress { /** 刚好命中 **/
                return item.offset
            }
            
            if item.element < progress {
                index = item.offset
                continue
            }
            
            if item.element > progress {
                return index
            }
        }
        return nil
    }
    
    // 每行歌词结束计算分数
    func lyricsLineEnds(lineIndex: Int) {
        guard !scoreArray.isEmpty, let dataArray = dataArray, !dataArray.isEmpty else {
            setScoreArray(lineIndex: lineIndex)
            let cumulativeScore = currentScore > totalScore ? totalScore : currentScore
            delegate?.agoraKaraokeScore?(score: 0,
                                         cumulativeScore: cumulativeScore,
                                         totalScore: totalScore)
            return
        }
        let minCalcuScore = scoreConfig?.minCalcuScore ?? 40
        let score = scoreArray.map({ $0.score }).filter({ $0 >= minCalcuScore }).reduce(0, +) / Double(scoreArray.count)
        currentScore += score
        let cumulativeScore = currentScore > totalScore ? totalScore : currentScore
        Log.info(text: "====> agoraKaraokeScore: \(score) minCalcuScore:\(minCalcuScore)", tag: logTag)
        for item in scoreArray.enumerated() {
            Log.info(text: "====> agoraKaraokeScore \(item.offset):  \(item.element.description)", tag: logTag)
        }
        
        delegate?.agoraKaraokeScore?(score: score,
                                     cumulativeScore: cumulativeScore,
                                     totalScore: totalScore)
        setScoreArray(lineIndex: lineIndex + 1)
    }
    
    private func setScoreArray(lineIndex: Int) {
        scoreArray.removeAll()
        if lineIndex < lrcSentence?.count ?? 0 {
            if let sentence = lrcSentence?[lineIndex]  {
                for tone in sentence.tones {
                    scoreArray.append(ToneScore(word: tone.word, stdPitch: tone.pitch))
                }
                Log.info(text: "====> setScoreArray \(lineIndex) \(sentence.tones.map({ $0.word }).reduce("", +))", tag: logTag)
            }
        }
    }
    
    private var pitchIsZeroCount = 0
    public func setVoicePitch(_ voicePitch: [Double]) {
        let pitch = voicePitch.last ?? 0
        Log.info(text: "setVoicePitch \(pitch)", tag: logTag)
        if pitch == 0 {
            pitchIsZeroCount += 1
        }
        else {
            pitchIsZeroCount = 0
        }
        if pitch > 0 || pitchIsZeroCount >= 5 {
            pitchIsZeroCount = 0
            calcuSongScore(pitch: pitch)
        }
        
    }
    
    var level: Double = 10
    var offset: Double = 0
    private var preModel: AgoraScoreItemModel?
    private var voicePitchChanger: VoicePitchChanger? = VoicePitchChanger()
    private func calcuSongScore(pitch: Double) {
        let time = currentTime * 1000
        guard let model = dataArray?.first(where: { time >= $0.startTime * 1000 && $0.endTime * 1000 >= time }), model.isEmptyCell == false
        else {
            let contantMax = _scoreConfig.scoreViewHeight - _scoreConfig.cursorHeight * 0.5
            cursorAnimation(y: contantMax, isDraw: false, pitch: pitch, word: "空白", standarPitch: 0, time: time.keep2)
            isDrawingCell = false
            triangleView.updateAlpha(at: 0)
            return
        }
        
        let calcuScore = scoreConfig?.lineCalcuScore ?? 100
        let voicePitch = voicePitchChanger?.handlePitch(stdPitch: model.pitch,
                                                        voicePitch: pitch,
                                                        wordMaxPitch: model.pitchMax) ?? pitch
        let score = AgoraKaraokeScoreView.calcultedTone(stdPitch: model.pitch,
                                                        stdPitchMin: model.pitchMin,
                                                        stdPitchMax: model.pitchMax,
                                                        pitch: pitch,
                                                        level: level,
                                                        offset: offset,
                                                        lineCalcuScore: calcuScore)
        
        let y = pitchToY(min: model.pitchMin, max: model.pitchMax, voicePitch)
        if score >= calcuScore * Double(_scoreConfig.hitScoreThreshold), voicePitch > 0 { /** 显示粒子动画 */
            Log.info(text: "show Animation \(score) y: \(y)", tag: logTag)
            delegate?.agoraKaraokeViewShouldUpdateUI?(showAnimation: true)
            cursorAnimation(y: y, isDraw: true, pitch: voicePitch, word: model.word, standarPitch: model.pitch, time: time.keep2)
            triangleView.updateAlpha(at: voicePitch <= 0 ? 0 : score / calcuScore)
        } else {
            delegate?.agoraKaraokeViewShouldUpdateUI?(showAnimation: false)
            cursorAnimation(y: y, isDraw: false, pitch: voicePitch, word: model.word, standarPitch: model.pitch, time: time.keep2)
            triangleView.updateAlpha(at: 0)
        }
        
        if voicePitch > 0 {
            let index = model.indexOfToneInSentence
            if index < scoreArray.count {
                let item = ToneScoreItem(score: score,
                                         word: model.word,
                                         originalPitch: pitch,
                                         pitch: voicePitch,
                                         currentTime: time)
                scoreArray[index].addItem(item: item)
            }
            else {
                Log.errorText(text: "out bounds, progress:\(time) word:\(model.word) index:\(index) count:\(scoreArray.count)", tag: logTag)
            }
        }
        preModel = model
    }
    
    /// 计算一个tone的分数
    /// - Parameters:
    ///   - pitch: 原始语音pitch
    /// - Returns: (分数，音调处理后的pitch)
    static func calcultedTone(stdPitch: Double,
                              stdPitchMin: Double,
                              stdPitchMax: Double,
                              pitch: Double,
                              level: Double,
                              offset: Double,
                              lineCalcuScore: Double) -> Double {
        if pitch == 0 { return 0 }
        var score: Double = 0
        if pitch >= stdPitchMin, pitch <= stdPitchMax {
            let fileTone = AgoraKaraokeScoreView.pitchToTone(pitch: stdPitch)
            if fileTone == 0 { return 0 }
            let voiceTone = AgoraKaraokeScoreView.pitchToTone(pitch: pitch)
            var match = 1 - level/100 * abs(voiceTone - fileTone)/fileTone + offset/100
            match = min(match, 1)
            match = max(match, 0)
            score = match * lineCalcuScore
        }
        return score
    }
    
    static func pitchToTone(pitch: Double) -> Double {
        let eps = 1e-6
        return (max(0, log(pitch / 55 + eps) / log(2))) * 12
    }
    
    var lastConstant: CGFloat = 0
    private func cursorAnimation(y: CGFloat,
                                 isDraw: Bool,
                                 pitch: Double,
                                 word: String,
                                 standarPitch: Double,
                                 time: Double) {
        let contantMax = _scoreConfig.scoreViewHeight - _scoreConfig.cursorHeight
        
        if word == "空白" { /** 句间空白 **/
            let debugText = "\(word)\n pitch：\(pitch.keep2)\n standarPitch： \(standarPitch.keep2)\n time: \(time)"
            delegate?.debugText?(text: debugText)
            let constant = contantMax
            lastConstant = constant
            cursorTopCons?.isActive = true
            if isDraw {
                isDrawingCell = true
            }
            Log.info(text: "=> \(word) \(pitch) \(standarPitch) fast down \(constant) isDrawingCell:\(isDrawingCell)", tag: logTag)
            UIView.animate(withDuration: 0.25, delay: 0, options:[.curveLinear]) {
                self.cursorTopCons?.constant = constant
                self.layoutIfNeeded()
            } completion: { _ in
                self.isDrawingCell = isDraw
            }
            lastConstant = constant
            return
        }
        
        if pitch == 0.0, lastConstant != 0 { /** pitch为0**/
            let debugText = "\(word)\n pitch：\(pitch.keep2)\n standarPitch： \(standarPitch.keep2)\n time: \(time)"
            delegate?.debugText?(text: debugText)
            
            let constant = contantMax
            
            cursorTopCons?.isActive = true
            if isDraw {
                isDrawingCell = true
            }
            Log.info(text: "=> \(word) \(pitch) \(standarPitch) fast down \(constant) isDrawingCell:\(isDrawingCell)", tag: logTag)
            UIView.animate(withDuration: 0.25, delay: 0, options:[.curveLinear]) {
                self.cursorTopCons?.constant = constant
                self.layoutIfNeeded()
            } completion: { _ in
                self.isDrawingCell = isDraw
            }
            lastConstant = constant
            return
        }
        
        /** pitch匹配上的情况 **/
        var constant = y - _scoreConfig.cursorHeight * 0.5
        constant = min(constant, contantMax)
        constant = max(0, constant)
        cursorTopCons?.constant = constant
        cursorTopCons?.isActive = true
        let debugText = "\(word)\n pos: \(constant)\n pitch：\(pitch.keep2)\n standarPitch： \(standarPitch.keep2) \n time: \(time)"
        delegate?.debugText?(text: debugText)
        if isDraw {
            isDrawingCell = true
        }
        self.layoutIfNeeded()
        self.isDrawingCell = isDraw
        Log.info(text: "=> \(word) \(pitch) \(standarPitch)  change \(constant) isDrawingCell:\(isDrawingCell)", tag: logTag)
        lastConstant = constant
        
    }
    
    private func updateDraw() {
        status = isDrawingCell ? .drawing : .new_layer
        if isDrawingCell {
            emitterView.startEmittering()
        } else {
            emitterView.stopEmittering()
        }
    }
    
    private func pitchToY(min: CGFloat, max: CGFloat, _ value: CGFloat) -> CGFloat {
        let viewH = _scoreConfig.scoreViewHeight - _scoreConfig.lineHeight
        let y = viewH - (viewH / (max - min) * (value - min))
        return y.isNaN ? 0 : y
    }
    
    private func calcuToWidth(time: TimeInterval) -> CGFloat {
        let w = _scoreConfig.lineWidth * time
        return w.isNaN ? 0 : abs(w)
    }
    
    private func createScoreData(data: [AgoraMiguLrcSentence]?) {
        guard let lrcData = data else { return }
        var dataArray = [AgoraScoreItemModel]()
        let tones = lrcData.flatMap { $0.tones }
        if let startData = insertStartLrcData(lrcData: tones) {
            dataArray.append(startData)
        }
        var preEndTime: Double = 0
        let pitchMin = CGFloat(tones.sorted(by: { $0.pitch < $1.pitch }).first?.pitch ?? 0) - 50
        let pitchMax = CGFloat(tones.sorted(by: { $0.pitch > $1.pitch }).first?.pitch ?? 0) + 50
        
        for sentence in lrcData {
            var indexOfToneInSentence = 0
            for tone in sentence.tones {
                let model = AgoraScoreItemModel()
                model.indexOfToneInSentence = indexOfToneInSentence
                var startTime = tone.begin
                let endTime = tone.end
                
                if preEndTime > 0, startTime > preEndTime  { /** 有空隙(跨句、字间) **/
                    let model = insertMiddelLrcData(startTime: startTime / 1000,
                                                    endTime: preEndTime / 1000)
                    model.left = dataArray.map { $0.width }.reduce(0, +)
                    dataArray.append(model)
                }
                
                if preEndTime > 0, startTime < preEndTime { /** 时间异常 **/
                    startTime = preEndTime
                }
                model.word = tone.word
                model.startTime = startTime / 1000
                model.endTime = endTime / 1000
                model.pitch = Double(tone.pitch)
                model.width = calcuToWidth(time: (endTime - startTime)/1000)
                model.left = dataArray.map { $0.width }.reduce(0, +)
                model.pitchMin = pitchMin
                model.pitchMax = pitchMax
                model.top = pitchToY(min: model.pitchMin, max: model.pitchMax, CGFloat(tone.pitch))
                
                preEndTime = endTime
                dataArray.append(model)
                
                indexOfToneInSentence += 1
            }
            lineEndTimes.append(preEndTime)
        }
        Log.info(text: "createScoreData \(dataArray.count)", tag: logTag)
        self.dataArray = dataArray
        preEndTime = 0
        
        setScoreArray(lineIndex: 0)
        
        /// check
        var time = 0.0
        for item in dataArray.enumerated() {
            if time > 0 {
                if abs(item.element.startTime - time) > 0.001 {
                    Log.errorText(text: "index \(item.offset)  \(item.element.word) time:\(time) startTime:\(item.element.startTime)", tag: logTag)
                }
            }
            time = item.element.endTime
        }
    }
    
    func getFirstToneBeginPosition() -> Double? {
        return dataArray?.first?.endTime
    }
    
    private func insertStartLrcData(lrcData: [AgoraMiguLrcTone]) -> AgoraScoreItemModel? {
        guard let firstTone = lrcData.first(where: { $0.pitch > 0 }) else { return nil }
        let endTime = firstTone.begin / 1000
        let model = AgoraScoreItemModel()
        model.width = calcuToWidth(time: endTime)
        model.isEmptyCell = true
        model.startTime = 0
        model.endTime = endTime
        return model
    }
    
    private func insertMiddelLrcData(startTime: Double,
                                     endTime: Double) -> AgoraScoreItemModel
    {
        // 中间间隔部分
        let model = AgoraScoreItemModel()
        let time = startTime - endTime
        model.startTime = endTime
        model.endTime = startTime
        model.width = calcuToWidth(time: time)
        model.isEmptyCell = true
        return model
    }
    
    private var cursorViewHeightConstraint: NSLayoutConstraint?
    private var cursorViewWidthConstraint: NSLayoutConstraint?
    private func setupUI() {
        addSubview(collectionView)
        addSubview(separatorVerticalLine)
        addSubview(separatorTopLine)
        addSubview(separatorBottomLine)
        emitterView.insertSubview(triangleView, at: 0)
        addSubview(cursorView)
        addSubview(emitterView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        separatorVerticalLine.translatesAutoresizingMaskIntoConstraints = false
        separatorTopLine.translatesAutoresizingMaskIntoConstraints = false
        separatorBottomLine.translatesAutoresizingMaskIntoConstraints = false
        cursorView.translatesAutoresizingMaskIntoConstraints = false
        triangleView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        verticalLineLeadingCons = separatorVerticalLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: _scoreConfig.innerMargin)
        verticalLineLeadingCons?.isActive = true
        separatorVerticalLine.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorVerticalLine.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorVerticalLine.widthAnchor.constraint(equalToConstant: 1).isActive = true
        
        separatorTopLine.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorTopLine.topAnchor.constraint(equalTo: topAnchor).isActive = true
        separatorTopLine.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorTopLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorBottomLine.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorBottomLine.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorBottomLine.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorBottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        cursorView.centerXAnchor.constraint(equalTo: separatorVerticalLine.centerXAnchor).isActive = true
        cursorTopCons = cursorView.topAnchor.constraint(equalTo: separatorVerticalLine.topAnchor, constant: _scoreConfig.scoreViewHeight - _scoreConfig.cursorHeight)
        cursorViewWidthConstraint = cursorView.widthAnchor.constraint(equalToConstant: _scoreConfig.cursorWidth)
        cursorViewWidthConstraint?.isActive = true
        cursorViewHeightConstraint = cursorView.heightAnchor.constraint(equalToConstant: _scoreConfig.cursorHeight)
        cursorViewHeightConstraint?.isActive = true
        cursorTopCons?.isActive = true
        
        triangleView.trailingAnchor.constraint(equalTo: cursorView.leadingAnchor, constant: 1).isActive = true
        triangleView.centerYAnchor.constraint(equalTo: cursorView.centerYAnchor).isActive = true
        triangleView.widthAnchor.constraint(equalToConstant: 45).isActive = true
        triangleView.heightAnchor.constraint(equalToConstant: 6).isActive = true
        
        emitterView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        emitterView.widthAnchor.constraint(equalToConstant: 400).isActive = true
        
        updateUI()
    }
    
    private func updateUI() {
        triangleView.config = _scoreConfig
        emitterView.config = _scoreConfig
        emitterView.isHidden = _scoreConfig.isHiddenEmitterView
        cursorViewWidthConstraint?.constant = _scoreConfig.cursorWidth
        cursorViewHeightConstraint?.constant = _scoreConfig.cursorHeight
        cursorView.layer.cornerRadius = _scoreConfig.cursorHeight * 0.5
        cursorView.backgroundColor = _scoreConfig.cursorColor
        separatorTopLine.backgroundColor = _scoreConfig.separatorLineColor
        separatorBottomLine.backgroundColor = _scoreConfig.separatorLineColor
        separatorVerticalLine.backgroundColor = _scoreConfig.separatorLineColor
        separatorTopLine.isHidden = _scoreConfig.isHiddenSeparatorLine
        separatorBottomLine.isHidden = _scoreConfig.isHiddenSeparatorLine
        separatorVerticalLine.isHidden = _scoreConfig.isHiddenVerticalSeparatorLine
        verticalLineLeadingCons?.constant = _scoreConfig.innerMargin
        verticalLineLeadingCons?.isActive = true
        cursorTopCons?.constant = _scoreConfig.scoreViewHeight - _scoreConfig.cursorHeight
        cursorTopCons?.isActive = true
        currentScore = _scoreConfig.defaultScore
    }
    
    func printLog(data: [AgoraScoreItemModel]?) {
        guard let list = data else {
            return
        }
        
        if let list = dataArray, !list.isEmpty {
            let width = list.map({ $0.width }).reduce(0, +)
            Log.info(text: "data reduce width \(width)", tag: logTag)
        }
        for info in list {
            let text = "--> \(info.word) dur: \(info.endTime - info.startTime) start: \(info.startTime) end: \(info.endTime) width: \(info.width)"
            Log.info(text: text, tag: logTag)
        }
    }
}

extension AgoraKaraokeScoreView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        let count = dataArray?.count ?? 0
        Log.info(text: "numberOfItemsInSection: \(count)", tag: logTag)
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AgoraKaraokeScoreCell",
                                                      for: indexPath) as! AgoraKaraokeScoreCell
        let model = dataArray?[indexPath.item]
        cell.setScore(with: model, config: _scoreConfig)
        return cell
    }
    
    public func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: dataArray?[indexPath.item].width ?? 0,
               height: _scoreConfig.scoreViewHeight)
    }
    
    public func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        0
    }
    
    public func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        0
    }
    
    public func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: _scoreConfig.innerMargin, bottom: 0, right: frame.width - _scoreConfig.innerMargin)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let dataArray = dataArray else { return }
        
        let moveX = scrollView.contentOffset.x
        for i in 0 ..< dataArray.count {
            let model = dataArray[i]
            let indexPath = IndexPath(item: i, section: 0)
            let cell = collectionView.cellForItem(at: indexPath) as? AgoraKaraokeScoreCell
            if model.left < moveX, moveX < model.left + model.width {
                if model.indexOfToneInSentence == 1, status == .drawing { /** 一句话的第二个字 **/
                    drawFirstToneInSentence(currentIndex: i,
                                            dataArray: dataArray)
                }
                model.offsetX = moveX
                model.status = status
            } else if model.left + model.width <= moveX {
                model.status = .end
            } else if moveX <= model.left {
                model.status = .`init`
            }
            cell?.setScore(with: model, config: _scoreConfig)
        }
    }
    
    private func drawFirstToneInSentence(currentIndex: Int,
                                         dataArray: [AgoraScoreItemModel]) {
        let lastIndex = currentIndex - 1
        guard lastIndex >= 0  else {
            return
        }
        
        let lastModel = dataArray[lastIndex]
        guard !lastModel.isEmptyCell else {
            return
        }
        
        let moveX = lastModel.left + lastModel.width - 0.0001
        lastModel.offsetX = moveX
        lastModel.status = .drawing
        let indexPath = IndexPath(item: lastIndex, section: 0)
        let cell = collectionView.cellForItem(at: indexPath) as? AgoraKaraokeScoreCell
        cell?.setHit()
    }
}

extension AgoraKaraokeScoreView {
    class ToneScore {
        var score: Double = 0
        let word: String
        var items = [ToneScoreItem]()
        let stdPitch: Int
        
        init(word: String, stdPitch: Int) {
            self.word = word
            self.stdPitch = stdPitch
        }
        
        func addItem(item: ToneScoreItem) {
            score = (score + item.score) / 2.0
            items.append(item)
        }
        
        var description: String {
            let dict: [String : Any] = ["word" : word,
                                        "score" : score,
                                        "stdPitch" : stdPitch,
                                        "items" : items]
            return "\(dict)"
        }
    }
    
    struct ToneScoreItem: CustomStringConvertible {
        let score: Double
        let word: String
        let originalPitch: Double
        let pitch: Double
        let currentTime: Double
        
        var description: String {
            let dict: [String : Any] = ["score" : score,
                                        "word" : word,
                                        "originalPitch" : originalPitch,
                                        "pitch" : pitch,
                                        "currentTime" : currentTime]
            return "\(dict)"
        }
    }
}
