//
//  ScoringView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class ScoringView: UIView {
    /// 评分视图高度
    public var viewHeight: CGFloat = 120 { didSet { updateUI() } }
    /// 渲染视图到顶部的间距
    public var topSpaces: CGFloat = 0 { didSet { updateUI() } }
    /// 游标的起始位置
    public var defaultPitchCursorX: CGFloat = 100 { didSet { updateUI() } }
    /// 音准线的高度
    public var standardPitchStickViewHeight: CGFloat = 3 { didSet { updateUI() } }
    /// 音准线的基准因子
    public var movingSpeedFactor: CGFloat = 120 { didSet { updateUI() } }
    /// 音准线默认的背景色
    public var standardPitchStickViewColor: UIColor = .gray { didSet { updateUI() } }
    /// 音准线匹配后的背景色
    public var standardPitchStickViewHighlightColor: UIColor = .orange { didSet { updateUI() } }
    /// 游标背景色
    public var localPitchCursorColor: UIColor = .systemPink { didSet { updateUI() } }
    /// 游标的半径
    public var localPitchCursorRadius: CGFloat = 20 { didSet { updateUI() } }
    /// 是否隐藏粒子动画效果
    public var particleEffectHidden: Bool = false { didSet { updateUI() } }
    /// 使用图片创建粒子动画
    public var emitterImages: [UIImage]? { didSet { updateUI() } }
    /// 动画颜色 (emitterImages为空时，默认使用颜色创建粒子动画)
    public var emitterColors: [UIColor] = [.red] { didSet { updateUI() } }
    /// 打分容忍度 范围：0-1
    public var hitScoreThreshold: Float = 0.7 { didSet { updateUI() } }
    /// use for debug only
    public var showDebugView = false { didSet { updateUI() } }
    
    var scoreLevel = 10
    var scoreCompensationOffset = 0
    
    var progress: Int = 0 { didSet { updateProgress() } }
    fileprivate let localPitchView = LocalPitchView()
    fileprivate let canvasView = ScoringCanvasView()
    /// use for debug only
    fileprivate let consoleView = ConsoleView()
    private var canvasViewTopConstraint, localPitchViewWidthConstraint: NSLayoutConstraint!
    
    fileprivate let vm = ScoringVM()
    weak var delegate: ScoringViewDelegate?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateUI()
        vm.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLyricData(data: LyricModel?) {
        vm.setLyricData(data: data)
    }
    
    func setPitch(pitch: Double) {
        vm.setPitch(pitch: pitch)
    }
    
    func setScoreAlgorithm(algorithm: IScoreAlgorithm) {
        vm.scoreAlgorithm = algorithm
    }
    
    func reset() {
        vm.reset()
    }
    
    private func updateProgress() {
        vm.progress = progress
    }
    
    private func setupUI() {
        addSubview(canvasView)
        addSubview(localPitchView)
        
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        localPitchView.translatesAutoresizingMaskIntoConstraints = false
        
        canvasView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        canvasViewTopConstraint = canvasView.topAnchor.constraint(equalTo: topAnchor, constant: topSpaces)
        canvasViewTopConstraint.isActive = true
        canvasView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        canvasView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        
        localPitchView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        localPitchView.topAnchor.constraint(equalTo: canvasView.topAnchor).isActive = true
        localPitchView.bottomAnchor.constraint(equalTo: canvasView.bottomAnchor).isActive = true
        let width = defaultPitchCursorX + LocalPitchView.scoreAnimateWidth /** 竖线的宽度是1 **/
        localPitchViewWidthConstraint = localPitchView.widthAnchor.constraint(equalToConstant: width)
        localPitchViewWidthConstraint.isActive = true
    }
    
    private func updateUI() {
        canvasView.defaultPitchCursorX = defaultPitchCursorX
        canvasView.standardPitchStickViewHeight = standardPitchStickViewHeight
        canvasView.movingSpeedFactor = movingSpeedFactor
        canvasView.standardPitchStickViewColor = standardPitchStickViewColor
        canvasView.standardPitchStickViewHighlightColor = standardPitchStickViewHighlightColor
        
        localPitchView.particleEffectHidden = particleEffectHidden
        localPitchView.defaultPitchCursorX = defaultPitchCursorX
        let width = defaultPitchCursorX + LocalPitchView.scoreAnimateWidth /** 竖线的宽度是1 **/
        localPitchViewWidthConstraint.constant = width
        
        canvasViewTopConstraint.constant = topSpaces
        
        vm.defaultPitchCursorX = defaultPitchCursorX
        vm.standardPitchStickViewHeight = standardPitchStickViewHeight
        vm.movingSpeedFactor = movingSpeedFactor
        vm.hitScoreThreshold = hitScoreThreshold
        vm.scoreLevel = scoreLevel
        vm.scoreCompensationOffset = scoreCompensationOffset
        
        delegate?.scoringViewShouldUpdateViewLayout(view: self)
        
        if showDebugView, !subviews.contains(consoleView) {
            addSubview(consoleView)
            consoleView.translatesAutoresizingMaskIntoConstraints = false
            consoleView.widthAnchor.constraint(equalToConstant: 80).isActive = true
            consoleView.heightAnchor.constraint(equalToConstant: 80).isActive = true
            consoleView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            consoleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
    }
}

extension ScoringView: ScoringVMDelegate {
    func sizeOfCanvasView(_ vm: ScoringVM) -> CGSize {
        return canvasView.bounds.size
    }
    
    func scoringVM(_ vm: ScoringVM,
                   didUpdateDraw standardInfos: [ScoringVM.DrawInfo],
                   highlightInfos: [ScoringVM.DrawInfo]) {
        canvasView.draw(standardInfos: standardInfos,
                        highlightInfos: highlightInfos)
    }
    
    func scoringVM(_ vm: ScoringVM,
                   didUpdateCursor centerY: CGFloat,
                   showAnimation: Bool,
                   pitch: Double) {
        localPitchView.setIndicatedViewY(y: centerY)
        showAnimation ? localPitchView.startEmitter() : localPitchView.stopEmitter()
        if showDebugView {
            let text = "y: \(Float(centerY)) \npitch: \(pitch.keep2) \nani: \(showAnimation) "
            consoleView.set(text: text)
        }
    }
    
    func scoringVM(_ vm: ScoringVM,
                   didFinishLineWith model: LyricLineModel,
                   score: Int,
                   lineIndex: Int,
                   lineCount: Int) {
        localPitchView.showScoreView(score: score)
        delegate?.scoringView(self,
                            didFinishLineWith: model,
                            score: score,
                            lineIndex: lineIndex,
                            lineCount: lineCount)
    }
}
