//
//  LyricMachine.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/3/13.
//

import Foundation

class LyricMachine {
    weak var delegate: LyricMachineDelegate?
    fileprivate var lyricData: LyricModel?
    fileprivate var dataList = [LyricCell.Model]()
    fileprivate var progress: Int = 0
    fileprivate var currentIndex = 0
    fileprivate var ignoreAnimationAfterDrag = false
    fileprivate var isStart = false
    fileprivate let logTag = "LyricMachine"
    fileprivate let queue = DispatchQueue(label: "queue.LyricMachine")
    
    // MARK: - Internal
    
    func setLyricData(data: LyricModel?) {
        queue.async { [weak self] in
            self?._setLyricData(data: data)
        }
    }
    
    func setProgress(progress: Int) {
        queue.async { [weak self] in
            self?._setProgress(progress: progress)
        }
    }
    
    func setDragEnd() {
        queue.async { [weak self] in
            self?._setDragEnd()
        }
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
    
    private func _setLyricData(data: LyricModel?) {
        lyricData = data
        dataList = data?.lines.map({ LyricCell.Model(text: $0.content,
                                                     progressRate: 0,
                                                     beginTime: $0.beginTime,
                                                     duration: $0.duration,
                                                     status: .normal,
                                                     tones: $0.tones) }) ?? []
        if let first = dataList.first { /** 默认高亮第一个 **/
            first.update(status: .selectedOrHighlighted)
        }
        invokeLyricMachine(didSetLyricData: dataList)
        isStart = true
        Log.info(text: "_setLyricData", tag: logTag)
    }
    
    private func _setProgress(progress: Int) {
        guard let data = lyricData else { return }
        let remainingTime = data.preludeEndPosition - progress
        invokeLyricMachine(didUpdate: remainingTime)
        
        if currentIndex < dataList.count {
            if let item = dataList.enumerated().first(where: { progress < $0.element.endTime }) { /** 找出第一个要高亮的 **/
                let newCurrentIndex = item.offset
                
                if newCurrentIndex != currentIndex { /** 切换了新的 **/
                    /// 恢复上一个
                    let lastIndex = currentIndex
                    let last = dataList[lastIndex]
                    last.update(status: .normal)
                    last.update(progressRate: 0)
                    let lastIndexPath = IndexPath(row: lastIndex, section: 0)
                    
                    /// 更新当前
                    currentIndex = newCurrentIndex
                    let current = dataList[currentIndex]
                    current.update(status: .selectedOrHighlighted)
                    var progressRate: Double = 0
                    if progress > item.element.beginTime, progress <= item.element.endTime { /** 计算比例 **/
                        progressRate = LyricMachine.calculateProgressRate(progress: progress,
                                                                          model: item.element,
                                                                          isTimeAccurateToWord: data.sourceType == .xml) ?? current.progressRate
                    }
                    current.update(progressRate: progressRate)
                    let indexPath = IndexPath(row: currentIndex, section: 0)
                    
                    let text = "new \(currentIndex) progressRate: \(progressRate) progress:\(progress)"
                    Log.debug(text: text, tag: logTag)
                    invokeLyricMachine(didStartLineAt: indexPath, oldIndexPath: lastIndexPath, animated: !ignoreAnimationAfterDrag)
                    ignoreAnimationAfterDrag = false
                    invokeLyricMachine(didUpdateConsloe: text)
                    return
                }
                if data.sourceType == .xml {
                    if newCurrentIndex == currentIndex,
                       progress > item.element.beginTime,
                       progress <= item.element.endTime { /** 还在原来的句子 **/
                        
                        let current = dataList[currentIndex]
                        let progressRate: Double = LyricMachine.calculateProgressRate(progress: progress, model: item.element, isTimeAccurateToWord: true) ?? current.progressRate
                        current.update(progressRate: progressRate)
                        let indexPath = IndexPath(row: currentIndex, section: 0)
                        invokeLyricMachine(didUpdateLineAt: indexPath)
                        
                        let text = "append \(currentIndex) progressRate: \(progressRate) progress:\(progress)"
                        Log.debug(text: text, tag: logTag)
                        invokeLyricMachine(didUpdateConsloe: text)
                    }
                }
            }
        }
    }
    
    private func _setDragEnd() {
        ignoreAnimationAfterDrag = true
        Log.info(text: "_setDragEnd", tag: logTag)
    }
    
    private func _reset() {
        isStart = false
        lyricData = nil
        dataList = []
        currentIndex = 0
        progress = 0
        ignoreAnimationAfterDrag = false
        Log.info(text: "_reset", tag: logTag)
    }
}

extension LyricMachine {
    /// 计算句子的进度
    /// - Parameters:
    /// - Returns: `nil` 表示无法计算, 其他： [0, 1]
    static func calculateProgressRate(progress: Int, model: LyricCell.Model, isTimeAccurateToWord: Bool) -> Double? {
        guard isTimeAccurateToWord else {
            return 0.0
        }
        
        var lastEndIndex = -1
        let toneCount = model.tones.filter({ $0.word.isEmpty == false }).count
        for (index, tone) in model.tones.enumerated() {
            if progress >= tone.endTime {
                lastEndIndex = index
            }
            if progress >= tone.beginTime, progress <= tone.beginTime + tone.duration {
                let progressRate = Double((progress - tone.beginTime)) / Double(tone.duration)
                let total = (Double(index) + progressRate) / Double(toneCount)
                return total
            }
        }
        
        if lastEndIndex != -1 {
            let total = Double(lastEndIndex+1) / Double(toneCount)
            return total
        }
        return 0.0
    }
}
