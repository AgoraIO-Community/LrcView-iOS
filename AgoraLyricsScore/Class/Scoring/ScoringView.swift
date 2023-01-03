//
//  ScoringView.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import UIKit

public class ScoringView: UIView {
    /// 评分视图高度
    public var viewHeight: CGFloat = 100
    /// 游标的起始位置
    public var defaultPitchCursorX: CGFloat = 100
    /// 音准线的高度
    public var standardPitchStickViewHeight: CGFloat = 10
    /// 音准线的基准因子
    public var movingSpeedFactor: CGFloat = 120
    /// 音准线默认的背景色
    public var standardPitchStickViewColor: UIColor = .gray
    /// 音准线匹配后的背景色
    public var standardPitchStickViewHighlightColor: UIColor = .orange
    /// 分割线的颜色
    public var separatorColor: UIColor = .systemPink
    /// 是否隐藏垂直分割线
    public var isVerticalSeparatorLineHidden: Bool = false
    /// 是否隐藏上下分割线
    public var separatorHidden: Bool = false
    /// 游标背景色
    public var localPitchCursorColor: UIColor = .systemPink
    /// 游标的半径
    public var localPitchCursorRadius: CGFloat = 20
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
    public var isRankViewHidden: Bool = false
    /// 等级视图高
    public var gradeViewHeight: CGFloat = 20
    /// 等级视图宽
    public var gradeViewWidth: CGFloat = 200
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
    
    fileprivate let lineView = UIView()
    fileprivate let canvasView = ScoringCanvasView()
    var progress: Int = 0 { didSet { updateProgress() } }
    fileprivate var dataList = [Info]()
    fileprivate var widthPreMs: CGFloat { movingSpeedFactor / 1000 }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        lineView.backgroundColor = separatorColor
        addSubview(canvasView)
        addSubview(lineView)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        
        lineView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        lineView.leftAnchor.constraint(equalTo: leftAnchor, constant: defaultPitchCursorX).isActive = true
        lineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        lineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        canvasView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        canvasView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        canvasView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        canvasView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
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
        
        let standardInfos = filterInfos(infos: dataList,
                                        beginTime: beginTime,
                                        endTime: endTime)
        canvasView.draw(progress: progress,
                        standardInfos: standardInfos,
                        highlightInfos: [])
    }
    
    func setLyricData(data: LyricModel?) {
        guard let lyricData = data else { return }
        dataList = []
        for line in lyricData.lines {
            for tone in line.tones {
                let info = Info(beginTime: tone.beginTime,
                                duration: tone.duration,
                                word: tone.word,
                                pitch: tone.pitch)
                dataList.append(info)
            }
        }
        let pitchs = dataList.filter({ $0.word != " " }).map({ $0.pitch })
        let maxPitch = pitchs.max() ?? 0
        let minPitch = pitchs.min() ?? 0
        /// UI上的一个点对于的pitch数量
        let pitchPerPoint = (CGFloat(maxPitch) - CGFloat(minPitch)) / viewHeight
        let extend = pitchPerPoint * standardPitchStickViewHeight
        canvasView.maxPitch = maxPitch + extend
        canvasView.minPitch = minPitch - extend
        progress = 0
    }
    
    private func filterInfos(infos: [Info],
                             beginTime: Int,
                             endTime: Int) -> [Info] {
        var result = [Info]()
        for info in infos {
            if info.beginTime >= endTime {
                break
            }
            if info.endTime <= beginTime {
                continue
            }
            result.append(info)
        }
        return result
    }
}

extension ScoringView {
    class Info {
        public let beginTime: Int
        public let duration: Int
        public let word: String
        public let pitch: Double
        
        init(beginTime: Int,
             duration: Int,
             word: String,
             pitch: Double) {
            self.beginTime = beginTime
            self.duration = duration
            self.word = word
            self.pitch = pitch
        }
        
        var endTime: Int {
            beginTime + duration
        }
    }
}

