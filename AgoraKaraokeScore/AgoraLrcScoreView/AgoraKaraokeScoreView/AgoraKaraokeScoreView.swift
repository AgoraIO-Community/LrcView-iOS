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
}

@objcMembers
class AgoraKaraokeScoreView: UIView {
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

    private lazy var separatorVerticalLine: UIView = {
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

    private lazy var cursorView: UIView = {
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
    private var decimalCount: Int = 0
    private var totalTime: TimeInterval = 0
    private var isDrawingCell: Bool = false {
        didSet {
            updateDraw()
        }
    }

    private var totalScore: Double = 0
    private var currentScore: Double = 50
    private var isInsertEnd: Bool = false
    private var pitchCount: Int = 0
    private var scoreArray: [Double] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        currentScore = _scoreConfig.defaultScore
        currentTime = 0
        totalTime = 0
        isInsertEnd = false
        decimalCount = 0
        pitchCount = 0
        scoreArray.removeAll()
        dataArray = []
        collectionView.reloadData()
    }
    
    func setTotalTime(totalTime: TimeInterval) {
        if decimalCount <= 0 {
            let count = Int("\(totalTime)".components(separatedBy: ".").last?.count ?? 3)
            decimalCount = count - 1
        }
        createScoreData(data: lrcSentence)
        if isInsertEnd == false {
            guard let model = insertEndLrcData(lrcData: lrcSentence, totalTime: totalTime) else { return }
            dataArray?.append(model)
            isInsertEnd = true
        }
        self.totalTime = totalTime
    }

    func start(currentTime: TimeInterval, totalTime: TimeInterval) {
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
        collectionView.setContentOffset(CGPoint(x: pointX, y: 0),
                                        animated: false)
    }

    func scrollToTop(animation: Bool = false) {
        guard !collectionView.visibleCells.isEmpty else { return }
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: animation)
    }
    
    // 每行歌词结束计算分数
    func lyricsLineEnds() {
        guard !scoreArray.isEmpty, let dataArray = dataArray, !dataArray.isEmpty else {
            pitchCount = 0
            scoreArray.removeAll()
            return
        }
        let score = scoreArray.reduce(0, +) / Double(pitchCount)
        currentScore += score
        delegate?.agoraKaraokeScore?(score: score,
                                     cumulativeScore: currentScore > totalScore ? totalScore : currentScore,
                                     totalScore: totalScore)
        pitchCount = 0
        scoreArray.removeAll()
    }

    private var pitchIsZeroCount = 0
    public func setVoicePitch(_ voicePitch: [Double]) {
        let pitch = voicePitch.last ?? 0
        if pitch == 0 {
            pitchIsZeroCount += 1
        }
        else {
            pitchIsZeroCount = 0
        }
        if pitch > 0 || pitchIsZeroCount >= 8 {
            pitchIsZeroCount = 0
            calcuSongScore(pitch: pitch)
        }
    }

    private var preModel: AgoraScoreItemModel?
    private func calcuSongScore(pitch: Double) {
        print("pitch: \(pitch), \(currentTime)")
        /// 减去200ms。因为说话到sdk回调需要这个时间
        let time = currentTime * 1000 - 200
        guard let model = dataArray?.first(where: { time >= $0.startTime * 1000 && $0.endTime * 1000 >= time }), model.isEmptyCell == false
        else {
            isDrawingCell = false
//            cursorAnimation(y: _scoreConfig.scoreViewHeight - _scoreConfig.cursorHeight * 0.5, isDraw: false)
            triangleView.updateAlpha(at: 0)
            return
        }
        
        let calcuScore = scoreConfig?.lineCalcuScore ?? 100
        var score: Double = 0
        if pitch >= model.pitchMin, pitch <= model.pitchMax {
            let fileTone = pitchToTone(pitch: model.pitch)
            let voiceTone = pitchToTone(pitch: pitch)
            var match = 1 - abs(voiceTone - fileTone)/fileTone
            if match < 0 { match = 0 }
            score = match * calcuScore
        }
        
        let y = pitchToY(min: model.pitchMin, max: model.pitchMax, pitch)
        if score >= calcuScore * 0.9, pitch > 0 {
            cursorAnimation(y: y, isDraw: true, pitch: pitch)
            triangleView.updateAlpha(at: pitch <= 0 ? 0 : score / calcuScore)
        } else {
            cursorAnimation(y: y, isDraw: false, pitch: pitch)
            triangleView.updateAlpha(at: 0)
        }
        if score >= scoreConfig?.minCalcuScore ?? 40 && pitch > 0 {
            scoreArray.append(score)
            pitchCount += 1
        }
        preModel = model
    }
    
    private func pitchToTone(pitch: Double) -> Double {
        let eps = 1e-6
        return (max(0, log(pitch / 55 + eps) / log(2))) * 12
    }

    var lastConstant: CGFloat = 0
    private func cursorAnimation(y: CGFloat,
                                 isDraw: Bool,
                                 pitch: Double) {
        let contantMax = _scoreConfig.scoreViewHeight - _scoreConfig.cursorHeight * 0.5
        var constant = y - _scoreConfig.cursorHeight * 0.5
        let durrtion: TimeInterval = 0.16

        if pitch == 0.0, lastConstant != 0 { /** 为0的情况 快速下降，进行缓降处理 **/
            print(">>> 下降 前 \(constant) max(\(contantMax))")
            constant = min(lastConstant + 0.12 * contantMax, contantMax)
            print(">>> 下降 后\(constant)")
            cursorTopCons?.constant = constant
            cursorTopCons?.isActive = true
            if isDraw {
                isDrawingCell = true
            }
            UIView.animate(withDuration: durrtion, delay: 0, options:[]) {
                self.layoutIfNeeded()
            } completion: { _ in
                self.isDrawingCell = isDraw
            }
        }
        else { /** 上升、不变、慢速下降 **/
            constant = min(constant, contantMax)
            constant = max(0, constant)
            cursorTopCons?.constant = constant
            cursorTopCons?.isActive = true
            print(">>> 上升 不变 慢速下降 \(constant)")
            if constant > lastConstant {
                print(">>> == lastConstant:\(lastConstant) constant:\(constant)")
            }
            if isDraw {
                isDrawingCell = true
            }
            UIView.animate(withDuration: durrtion, delay: 0, options:[.curveEaseIn]) {
                self.layoutIfNeeded()
            } completion: { _ in
                self.isDrawingCell = isDraw
            }
        }
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
        let w = _scoreConfig.lineWidth * roundToPlaces(value: time, places: decimalCount)
        return w.isNaN ? 0 : abs(w)
    }

    private func roundToPlaces(value: Double, places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(value * divisor) / divisor
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
        for i in 0 ..< tones.count {
            let tone = tones[i]
            
            let model = AgoraScoreItemModel()
            let startTime = tone.begin / 1000
            let endTime = tone.end / 1000
            if i<5 {
                print("word:\(tone.word), start:\(startTime), end:\(endTime), pitch: \(tone.pitch)")
            }
            if preEndTime > 0, preEndTime != startTime {
                let model = insertMiddelLrcData(startTime: startTime,
                                                endTime: preEndTime)
                model.leftKM = dataArray.map { $0.widthKM }.reduce(0, +)
                dataArray.append(model)
            }
            model.word = tone.word
            model.startTime = roundToPlaces(value: startTime, places: decimalCount)
            model.endTime = roundToPlaces(value: endTime, places: decimalCount)
            model.pitch = Double(tone.pitch)
            model.widthKM = calcuToWidth(time: endTime - startTime)
            model.leftKM = dataArray.map { $0.widthKM }.reduce(0, +)
            model.pitchMin = pitchMin
            model.pitchMax = pitchMax
            model.topKM = pitchToY(min: model.pitchMin, max: model.pitchMax, CGFloat(tone.pitch))

            preEndTime = endTime
            dataArray.append(model)
        }
        self.dataArray = dataArray
    }

    private func insertStartLrcData(lrcData: [AgoraMiguLrcTone]) -> AgoraScoreItemModel? {
        guard let firstTone = lrcData.first(where: { $0.pitch > 0 }) else { return nil }
        let endTime = roundToPlaces(value: firstTone.begin / 1000 , places: decimalCount)
        let model = AgoraScoreItemModel()
        model.widthKM = calcuToWidth(time: endTime)
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
        model.startTime = startTime
        model.endTime = endTime
        model.widthKM = calcuToWidth(time: time)
        model.isEmptyCell = true
        return model
    }

    private func insertEndLrcData(lrcData: [AgoraMiguLrcSentence]?, totalTime: TimeInterval) -> AgoraScoreItemModel? {
        guard let lrcData = lrcData else { return nil }
        let tones = lrcData.flatMap { $0.tones }
        guard let firstTone = tones.last(where: { $0.pitch > 0 }) else { return nil }
        let endTime = totalTime - roundToPlaces(value: (firstTone.end / 1000), places: decimalCount)
        let model = AgoraScoreItemModel()
        model.widthKM = calcuToWidth(time: endTime)
        model.isEmptyCell = true
        model.startTime = roundToPlaces(value: firstTone.end / 1000, places: decimalCount)
        model.endTime = model.startTime + endTime
        model.leftKM = (dataArray?.last?.leftKM ?? 0) + (dataArray?.last?.widthKM ?? 0)
        return model
    }

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
        cursorView.widthAnchor.constraint(equalToConstant: _scoreConfig.cursorWidth).isActive = true
        cursorView.heightAnchor.constraint(equalToConstant: _scoreConfig.cursorHeight).isActive = true
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
}

extension AgoraKaraokeScoreView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        dataArray?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AgoraKaraokeScoreCell",
                                                      for: indexPath) as! AgoraKaraokeScoreCell
        let model = dataArray?[indexPath.item]
        cell.setScore(with: model, config: _scoreConfig)
        return cell
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: dataArray?[indexPath.item].widthKM ?? 0,
               height: _scoreConfig.scoreViewHeight)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        0
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: _scoreConfig.innerMargin, bottom: 0, right: frame.width - _scoreConfig.innerMargin)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let dataArray = dataArray else { return }

        let moveX = scrollView.contentOffset.x
        for i in 0 ..< dataArray.count {
            let model = dataArray[i]
            let indexPath = IndexPath(item: i, section: 0)
            let cell = collectionView.cellForItem(at: indexPath) as? AgoraKaraokeScoreCell
            if model.leftKM < moveX, moveX < model.leftKM + model.widthKM {
                model.offsetXKM = moveX
                model.status = status
            } else if model.leftKM + model.widthKM <= moveX {
                model.status = .end
            } else if moveX <= model.leftKM {
                model.status = .`init`
            }
            cell?.setScore(with: model, config: _scoreConfig)
        }
    }
}
