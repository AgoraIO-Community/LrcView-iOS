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
    fileprivate var dataList = [LyricCellModel]()
    fileprivate var progress: UInt = 0
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
    
    func setProgress(progress: UInt) {
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
        
        guard let data = data else {
            dataList = []
            invokeLyricMachine(didSetLyricData: dataList)
            isStart = true
            Log.info(text: "_setLyricData nil", tag: logTag)
            return
        }
        
        let isKrcType = data.lyricsType == .krc
        dataList = data.lines.map({ line in
            let duration = isKrcType ? line.tones.map({ $0.duration }).reduce(0, +) : line.duration
            return LyricCellModel(text: line.content,
                                   progressRate: 0,
                                   beginTime: line.beginTime,
                                   duration: duration,
                                   status: .normal,
                                   tones: line.tones)
        })
        if let first = dataList.first { /** 默认高亮第一个 **/
            first.update(status: .selectedOrHighlighted)
        }
        invokeLyricMachine(didSetLyricData: dataList)
        isStart = true
        Log.info(text: "_setLyricData", tag: logTag)
    }
    
    private func _setProgress(progress: UInt) {
        guard let data = lyricData else { return }
        let remainingTime = Int(data.preludeEndPosition) - Int(progress)
        invokeLyricMachine(didUpdate: remainingTime)
        let scrollByWord = data.lyricsType == .xml || data.lyricsType == .krc
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
                                                                          scrollByWord: scrollByWord) ?? current.progressRate
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
                
                if newCurrentIndex == currentIndex,
                   progress > item.element.beginTime,
                   progress <= item.element.endTime { /** 还在原来的句子 **/
                    
                    let current = dataList[currentIndex]
                    let progressRate: Double = LyricMachine.calculateProgressRate(progress: progress,
                                                                                  model: item.element,
                                                                                  scrollByWord: scrollByWord) ?? current.progressRate
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
    ///   - scrollByWord: 是否可以打分（数据源是lrc格式不可打分）
    /// - Returns: `nil` 表示无法计算, 其他： [0, 1]
    static func calculateProgressRate(progress: UInt,
                                      model: LyricCellModel,
                                      scrollByWord: Bool) -> Double? {
        if scrollByWord {
            let toneCount = model.tones.filter({ $0.word.isEmpty == false }).count
            for (index, tone) in model.tones.enumerated() {
                if progress >= tone.beginTime, progress <= tone.beginTime + tone.duration {
                    /// calculated whole sentence's progress
                    let progressRate = Double((progress - tone.beginTime)) / Double(tone.duration)
                    let total = (Double(index) + progressRate) / Double(toneCount)
                    return total
                }
            }
            return nil
        }
        else {
            return 1
        }
    }
}
