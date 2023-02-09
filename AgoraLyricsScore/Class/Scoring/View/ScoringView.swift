//
//  ScoringView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class ScoringView: UIView {
    /// 评分视图高度
    @objc public var viewHeight: CGFloat = 120 { didSet { updateUI() } }
    /// 渲染视图到顶部的间距
    @objc public var topSpaces: CGFloat = 0 { didSet { updateUI() } }
    /// 游标的起始位置
    @objc public var defaultPitchCursorX: CGFloat = 100 { didSet { updateUI() } }
    /// 音准线的高度
    @objc public var standardPitchStickViewHeight: CGFloat = 3 { didSet { updateUI() } }
    /// 音准线的基准因子
    @objc public var movingSpeedFactor: CGFloat = 120 { didSet { updateUI() } }
    /// 音准线默认的背景色
    @objc public var standardPitchStickViewColor: UIColor = .gray { didSet { updateUI() } }
    /// 音准线匹配后的背景色
    @objc public var standardPitchStickViewHighlightColor: UIColor = .colorWithHex(hexStr: "#FF8AB4") { didSet { updateUI() } }
    /** 游标偏移量(X轴) 游标的中心到竖线中心的距离
     - 等于0：游标中心点和竖线中线点重合
     - 小于0: 游标向左偏移
     - 大于0：游标向向偏移 **/
    @objc public var localPitchCursorOffsetX: CGFloat = -3 { didSet { updateUI() } }
    /// 游标的图片
    @objc public var localPitchCursorImage: UIImage? = nil { didSet { updateUI() } }
    /// 是否隐藏粒子动画效果
    @objc public var particleEffectHidden: Bool = false { didSet { updateUI() } }
    /// 使用图片创建粒子动画
    @objc public var emitterImages: [UIImage]? { didSet { updateUI() } }
    /// 打分容忍度 范围：0-1
    @objc public var hitScoreThreshold: Float = 0.7 { didSet { updateUI() } }
    /// use for debug only
    @objc public var showDebugView = false { didSet { updateUI() } }
    
    var scoreLevel = 10 { didSet { updateUI() } }
    var scoreCompensationOffset = 0 { didSet { updateUI() } }
    
    var progress: Int = 0 { didSet { updateProgress() } }
    fileprivate let localPitchView = LocalPitchView()
    fileprivate let canvasView = ScoringCanvasView()
    /// use for debug only
    fileprivate let consoleView = ConsoleView()
    private var canvasViewHeightConstraint, localPitchViewWidthConstraint: NSLayoutConstraint!
    
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
    
    /// 获取当前累计分数
    @objc public func getCumulativeScore() -> Int {
        vm.getCumulativeScore()
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
    
    func dragBegain() {
        vm.dragBegain()
    }
    
    func dragDidEnd(position: Int) {
        vm.dragDidEnd(position: position)
    }
    
    func reset() {
        vm.reset()
        localPitchView.reset()
        canvasView.reset()
    }
    
    private func updateProgress() {
        vm.setProgress(progress: progress)
    }
    
    private func setupUI() {
        addSubview(canvasView)
        addSubview(localPitchView)
        
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        localPitchView.translatesAutoresizingMaskIntoConstraints = false
        
        canvasView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        canvasView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        canvasView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        canvasViewHeightConstraint = canvasView.heightAnchor.constraint(equalToConstant: viewHeight)
        canvasViewHeightConstraint.isActive = true
        
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
        localPitchView.emitterImages = emitterImages
        localPitchView.defaultPitchCursorX = defaultPitchCursorX
        localPitchView.localPitchCursorOffsetX = localPitchCursorOffsetX
        localPitchView.localPitchCursorImage = localPitchCursorImage
        
        let width = defaultPitchCursorX + LocalPitchView.scoreAnimateWidth /** 竖线的宽度是1 **/
        localPitchViewWidthConstraint.constant = width
        canvasViewHeightConstraint.constant = viewHeight
        
        vm.defaultPitchCursorX = defaultPitchCursorX
        vm.standardPitchStickViewHeight = standardPitchStickViewHeight
        vm.movingSpeedFactor = movingSpeedFactor
        vm.hitScoreThreshold = hitScoreThreshold
        vm.scoreLevel = scoreLevel
        vm.scoreCompensationOffset = scoreCompensationOffset
        
        delegate?.scoringViewShouldUpdateViewLayout(view: self)
        
        if showDebugView {
            if !subviews.contains(consoleView) {
                addSubview(consoleView)
                consoleView.translatesAutoresizingMaskIntoConstraints = false
                consoleView.widthAnchor.constraint(equalToConstant: 80).isActive = true
                consoleView.heightAnchor.constraint(equalToConstant: 80).isActive = true
                consoleView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
                consoleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            }
        }
        else {
            consoleView.removeFromSuperview()
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
                   debugInfo: ScoringVM.DebugInfo) {
        localPitchView.setIndicatedViewY(y: centerY)
        showAnimation ? localPitchView.startEmitter() : localPitchView.stopEmitter()
        if showDebugView {
            let text = "y: \(Float(centerY)) \npitch: \(debugInfo.pitch.keep2) \nani: \(showAnimation) \nw:\(debugInfo.hitedInfo?.word ?? "") \nstd:\(debugInfo.hitedInfo?.pitch ?? 0) progress: \(debugInfo.progress)"
            consoleView.set(text: text)
        }
    }
    
    func scoringVM(_ vm: ScoringVM,
                   didFinishLineWith model: LyricLineModel,
                   score: Int,
                   cumulativeScore: Int,
                   lineIndex: Int,
                   lineCount: Int) {
        localPitchView.showScoreView(score: score)
        delegate?.scoringView(self,
                              didFinishLineWith: model,
                              score: score,
                              cumulativeScore: cumulativeScore,
                              lineIndex: lineIndex,
                              lineCount: lineCount)
    }
}
