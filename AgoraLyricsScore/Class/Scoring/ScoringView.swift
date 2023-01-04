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
    
    var progress: Int = 0 { didSet { updateProgress() } }
    fileprivate let gradeView = GradeView()
    fileprivate let localPitchView = LocalPitchView()
    fileprivate let canvasView = ScoringCanvasView()
    fileprivate var dataList = [Info]()
    fileprivate var widthPreMs: CGFloat { movingSpeedFactor / 1000 }
    fileprivate var currentVisiableInfos = [Info]()
    fileprivate var currentHighlightInfos = [Info]()
    fileprivate var maxPitch: Double = 0
    fileprivate var minPitch: Double = 0
    fileprivate var scoreLevel = 0
    fileprivate var scoreCompensationOffset = 0
    /// 产生pitch花费的时间
    fileprivate let pitchDuration = 50
    /// 间距
    fileprivate let gradeViewSpaces: CGFloat = 15
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
    
    private func updateProgress() {
        /// 视图最左边到游标这段距离对应的时长
        let defaultPitchCursorXTime = Int(defaultPitchCursorX / widthPreMs)
        /// 游标到视图最右边对应的时长
        let remainTime = Int((frame.width - defaultPitchCursorX) / widthPreMs)
        /// 需要显示音高的开始时间
        let beginTime = max(progress - defaultPitchCursorXTime, 0)
        /// 需要显示音高的结束时间
        let endTime = progress + remainTime
        
        currentVisiableInfos = filterStandardInfos(infos: dataList,
                                                   beginTime: beginTime,
                                                   endTime: endTime)
        currentHighlightInfos = filterHighlightInfos(infos: currentHighlightInfos,
                                                     beginTime: beginTime,
                                                     endTime: endTime)
        canvasView.draw(progress: progress,
                        standardInfos: currentVisiableInfos,
                        highlightInfos: currentHighlightInfos)
        
        //        if let currentInfo = getCurrentInfo(progress: progress, currentVisiableInfos: currentVisiableInfos) { /** debug **/
        //            setPitch(pitch: currentInfo.pitch)
        //        }
    }
    
    func setLyricData(data: LyricModel?) {
        guard let lyricData = data else { return }
        /** create data **/
        createData(data: lyricData)
        
        /** set value **/
        let pitchs = dataList.filter({ $0.word != " " }).map({ $0.pitch })
        let maxValue = pitchs.max() ?? 0
        let minValue = pitchs.min() ?? 0
        /// UI上的一个点对于的pitch数量
        let pitchPerPoint = (CGFloat(maxValue) - CGFloat(minValue)) / canvasView.bounds.height
        let extend = pitchPerPoint * standardPitchStickViewHeight
        maxPitch = maxValue + extend
        minPitch = max(minValue - extend, 0)
        canvasView.maxPitch = maxPitch
        canvasView.minPitch = minPitch
        progress = 0
    }
    
    private func createData(data: LyricModel) {
        dataList = []
        for line in data.lines {
            for tone in line.tones {
                let info = Info(beginTime: tone.beginTime,
                                duration: tone.duration,
                                word: tone.word,
                                pitch: tone.pitch,
                                drawBeginTime: tone.beginTime,
                                drawDuration: tone.duration)
                dataList.append(info)
            }
        }
    }
    
    private func filterStandardInfos(infos: [Info],
                                     beginTime: Int,
                                     endTime: Int) -> [Info] {
        var result = [Info]()
        for info in infos {
            if info.drawBeginTime >= endTime {
                break
            }
            if info.endTime <= beginTime {
                continue
            }
            result.append(info)
        }
        return result
    }
    
    private func filterHighlightInfos(infos: [Info],
                                      beginTime: Int,
                                      endTime: Int) -> [Info] {
        return filterStandardInfos(infos: infos,
                                   beginTime: beginTime,
                                   endTime: endTime)
    }
    
    func setPitch(pitch: Double) {
        let y = getCenterY(pitch: pitch)
        localPitchView.setIndicatedViewY(y: y)
        if pitch != 0 {
            let _ = updateHighlightInfos(progress: progress,
                                         pitch: pitch,
                                         currentVisiableInfos: currentVisiableInfos)
        }
    }
    
    /// 更新高亮数据
    /// - Returns: 返回击中的数据
    private func updateHighlightInfos(progress: Int,
                                      pitch: Double,
                                      currentVisiableInfos: [Info]) -> Info? {
        if let preInfo = currentHighlightInfos.last,
           let preHitInfo = getHitedInfo(progress: progress, currentVisiableInfos: [preInfo])  { /** 判断是否可追加 **/
            let score = calculedScore(voicePitch: pitch, stdPitch: preInfo.pitch)
            if score >= hitScoreThreshold * 100 {
                let newDrawBeginTime = max(progress - pitchDuration, preHitInfo.beginTime)
                let distance = newDrawBeginTime - preHitInfo.drawEndTime
                
                if distance < pitchDuration { /** 追加 **/
                    let drawDuration = min(preHitInfo.drawDuration + pitchDuration + distance, preHitInfo.duration)
                    preHitInfo.drawDuration = drawDuration
                    return preHitInfo
                }
            }
        }
        
        if let stdInfo = getHitedInfo(progress: progress, currentVisiableInfos: currentVisiableInfos) { /** 新建 **/
            let score = calculedScore(voicePitch: pitch, stdPitch: stdInfo.pitch)
            if score >= hitScoreThreshold * 100 {
                let drawBeginTime = max(progress - pitchDuration, stdInfo.beginTime)
                let drawDuration = min(pitchDuration, stdInfo.duration)
                let info = Info(beginTime: stdInfo.beginTime,
                                duration: stdInfo.duration,
                                word: stdInfo.word,
                                pitch: stdInfo.pitch,
                                drawBeginTime: drawBeginTime,
                                drawDuration: drawDuration)
                currentHighlightInfos.append(info)
                return info
            }
        }
        
        return nil
    }
    
    /// 计算y的位置
    private func getCenterY(pitch: Double) -> CGFloat {
        let canvasViewHeight = canvasView.bounds.height
        
        if pitch <= 0 {
            return canvasViewHeight
        }
        
        if pitch < minPitch {
            return canvasViewHeight
        }
        if pitch > maxPitch {
            return 0
        }
        
        /// 映射成从0开始
        let value = pitch - minPitch
        /// 计算相对偏移
        let distance = (value / (maxPitch - minPitch)) * canvasViewHeight
        let y = canvasViewHeight - distance
        return y
    }
    
    private func getHitedInfo(progress: Int, currentVisiableInfos: [Info]) -> Info? {
        let pitchBeginTime = progress - pitchDuration/2
        return currentVisiableInfos.first { info in
            return pitchBeginTime >= info.drawBeginTime && pitchBeginTime <= info.endTime
        }
    }
    
    /// 计算tone分数
    private func calculedScore(voicePitch: Double, stdPitch: Double) -> Float {
        if voicePitch < minPitch || voicePitch > maxPitch {
            return 0
        }
        let stdTone = pitchToTone(pitch: stdPitch)
        let voiceTone = pitchToTone(pitch: voicePitch)
        var match = 1 - Float(scoreLevel/100) * Float(abs(voiceTone - stdTone)) + Float(scoreCompensationOffset/100)
        match = max(0, match)
        match = min(1, match)
        return match * 100
    }
    
    private func pitchToTone(pitch: Double) -> Double {
        let eps = 1e-6
        return (max(0, log(pitch / 55 + eps) / log(2))) * 12
    }
}

extension ScoringView {
    class Info {
        /// 标准开始时间 （来源自歌词文件）
        let beginTime: Int
        /// 标准时长 （来源自歌词文件）
        let duration: Int
        /// 需要绘制的开始时间
        let drawBeginTime: Int
        /// 需要绘制的时长
        var drawDuration: Int
        let word: String
        let pitch: Double
        
        init(beginTime: Int,
             duration: Int,
             word: String,
             pitch: Double,
             drawBeginTime: Int,
             drawDuration: Int) {
            self.beginTime = beginTime
            self.duration = duration
            self.word = word
            self.pitch = pitch
            self.drawBeginTime = drawBeginTime
            self.drawDuration = drawDuration
        }
        
        var endTime: Int {
            beginTime + duration
        }
        
        var drawEndTime: Int {
            drawBeginTime + drawDuration
        }
    }
}

