//
//  ProgressChecker.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/3/21.
//

import Foundation

protocol ProgressCheckerDelegate: NSObjectProtocol {
    func progressCheckerDidProgressPause()
}

/// check progress if pause
class ProgressChecker: NSObject {
    private var lastProgress = 0
    private var progress = 0
    private var isStart = false
    private let queue = DispatchQueue(label: "queue.progressChecker")
    weak var delegate: ProgressCheckerDelegate?
    private var isPause = false
    private var timer: DispatchSourceTimer?
    private let logTag = "ProgressChecker"
    
    // MARK: - Internal
    
    /// progress input
    func set(progress: Int) {
        queue.async { [weak self] in
            self?._set(progress: progress)
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
    
    private func _set(progress: Int) {
        self.progress = progress
        _start()
    }
    
    private func _start() {
        if isStart { return }
        isStart = true
        setupTimer()
    }
    
    private func _check() {
        guard progress > 0 else {
            return
        }
        if lastProgress == progress {
            if !isPause {
                invokeProgressCheckerDidProgressPause()
            }
            isPause = true
        }
        else {
            isPause = false
        }
        lastProgress = progress
    }
    
    private func _reset() {
        cancleTimer()
        isPause = false
        isStart = false
        lastProgress = 0
        progress = 0
    }
    
    private func setupTimer() {
        timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .seconds(0))
        timer?.setEventHandler { [weak self] in
            self?._check()
        }
        timer?.resume()
    }
    
    private func cancleTimer() {
        guard let t = timer else {
            return
        }
        t.cancel()
        timer = nil
    }
}

extension ProgressChecker {
    fileprivate func invokeProgressCheckerDidProgressPause() {
        if Thread.isMainThread {
            delegate?.progressCheckerDidProgressPause()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.progressCheckerDidProgressPause()
        }
    }
}

