//
//  ScoringView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class ScoringView: UIView {
    /// 评分视图高度
    public var viewHeight: CGFloat = 170 { didSet { updateUI() } }
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
    /// 分割线的颜色
    public var separatorColor: UIColor = .systemPink { didSet { updateUI() } }
    /// 是否隐藏垂直分割线
    public var isVerticalSeparatorLineHidden: Bool = false { didSet { updateUI() } }
    /// 是否隐藏上下分割线
    public var separatorHidden: Bool = false { didSet { updateUI() } }
    /// 游标背景色
    public var localPitchCursorColor: UIColor = .systemPink { didSet { updateUI() } }
    /// 游标的半径
    public var localPitchCursorRadius: CGFloat = 20 { didSet { updateUI() } }
    /// 是否隐藏粒子动画效果
    public var particleEffectHidden: Bool = false
    /// 使用图片创建粒子动画
    public var emitterImages: [UIImage]?
    /// 动画颜色 (emitterImages为空时，默认使用颜色创建粒子动画)
    public var emitterColors: [UIColor] = [.red]
    /// 自定义火焰效果图片
    public var fireEffectImage: UIImage?
    /// 火焰效果颜色 图片为空时使用颜色
    public var fireEffectColor: UIColor? = .yellow
    /// 是否隐藏等级视图
    public var isGradeViewHidden: Bool = false
    /// 等级视图高
    public var gradeViewHeight: CGFloat = 40
    /// 等级视图宽
    public var gradeViewWidth: CGFloat = UIScreen.main.bounds.width - 60
    /// 等级视图的正常颜色
    public var gradeViewNormalColor: UIColor = .gray
    /// 等级视图的高亮颜色 (渐变色)
    public var gradeViewHighlightColors: [UIColor] = [.blue]
    /// 评分激励是否显示
    public var incentiveViewHidden: Bool = false
    /// 评分激励的文字颜色 (渐变色)
    public var incentiveTextColor: [UIColor] = [.blue]
    /// 评分激励的文字大小
    public var incentiveTextFont: UIFont = .systemFont(ofSize: 18)
    /// 打分容忍度 范围：0-1
    public var hitScoreThreshold: Float = 0.7
    
    public var scoreLevel = 10
    public var scoreCompensationOffset = 0
    
    var progress: Int = 0 { didSet { updateProgress() } }
    fileprivate let gradeView = GradeView()
    fileprivate let localPitchView = LocalPitchView()
    fileprivate let canvasView = ScoringCanvasView()
    /// 间距
    fileprivate let gradeViewSpaces: CGFloat = 15
    fileprivate let vm = ScoringVM()
    weak var delegate: ScoringViewDelegate?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
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
    
    func reset() {
        vm.reset()
    }
    
    private func updateProgress() {
        vm.progress = progress
    }
    
    private func setupUI() {
        gradeView.backgroundColor = .blue
        addSubview(gradeView)
        addSubview(canvasView)
        addSubview(localPitchView)
        
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        localPitchView.translatesAutoresizingMaskIntoConstraints = false
        gradeView.translatesAutoresizingMaskIntoConstraints = false
        
        gradeView.topAnchor.constraint(equalTo: topAnchor, constant: gradeViewSpaces).isActive = true
        gradeView.widthAnchor.constraint(equalToConstant: gradeViewWidth).isActive = true
        gradeView.heightAnchor.constraint(equalToConstant: gradeViewHeight).isActive = true
        gradeView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        canvasView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        canvasView.topAnchor.constraint(equalTo: gradeView.bottomAnchor, constant: gradeViewSpaces).isActive = true
        canvasView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        canvasView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        
        localPitchView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        localPitchView.topAnchor.constraint(equalTo: canvasView.topAnchor).isActive = true
        localPitchView.bottomAnchor.constraint(equalTo: canvasView.bottomAnchor).isActive = true
        let width = defaultPitchCursorX + 1 * 0.5 /** 竖线的宽度是1 **/
        localPitchView.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    private func updateUI() {
        canvasView.defaultPitchCursorX = defaultPitchCursorX
        canvasView.standardPitchStickViewHeight = standardPitchStickViewHeight
        canvasView.movingSpeedFactor = movingSpeedFactor
        canvasView.standardPitchStickViewColor = standardPitchStickViewColor
        canvasView.standardPitchStickViewHighlightColor = standardPitchStickViewHighlightColor
        canvasView.separatorColor = separatorColor
        canvasView.isVerticalSeparatorLineHidden = isVerticalSeparatorLineHidden
        canvasView.separatorHidden = separatorHidden
        localPitchView.defaultPitchCursorX = defaultPitchCursorX
        
        vm.defaultPitchCursorX = defaultPitchCursorX
        vm.standardPitchStickViewHeight = standardPitchStickViewHeight
        vm.movingSpeedFactor = movingSpeedFactor
        vm.hitScoreThreshold = hitScoreThreshold
        vm.scoreLevel = scoreLevel
        vm.scoreCompensationOffset = scoreCompensationOffset
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
                   showAnimation: Bool) {
        localPitchView.setIndicatedViewY(y: centerY)
        showAnimation ? localPitchView.startEmitter() : localPitchView.stopEmitter()
    }
    
    func scoringVM(_ vm: ScoringVM,
                   didFinishLineWith model: LyricLineModel,
                   score: Int,
                   lineIndex: Int,
                   lineCount: Int) {
        delegate?.scoringVM(self,
                            didFinishLineWith: model,
                            score: score,
                            lineIndex: lineIndex,
                            lineCount: lineCount)
    }
}
