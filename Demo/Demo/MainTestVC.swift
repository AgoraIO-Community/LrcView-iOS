//
//  MainTestVC2.swift
//  Demo
//
//  Created by ZYP on 2024/4/23.
//

import UIKit
import AgoraLyricsScore
import AgoraRtcKit
import AgoraMccExService

class MainTestVC: UIViewController {
    /// 主视图
    private let mainView = MainView()
    /// MusicContentConter 管理实例
    private let mccManager = MCCManager()
    /// 进度进度校准和进度提供者
    private let progressProvider = ProgressProvider()
    private var songId = 40289835
    var lyricModel: LyricModel!
    let logTag = "MainTestVC"
    fileprivate var isSeeking = false
    fileprivate var canUseParamsSet = false
    fileprivate var noLyric = false
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
        
        if let token = Config.token, let userId = Config.userId {
            mccManager.initRtcEngine()
            mccManager.joinChannel()
            mccManager.initMccEx(pid: Config.pid,
                                 pKey: Config.pKey,
                                 token: token,
                                 userId: userId)
        }
        else {
            AccessProvider.fetchAccessData { [weak self](userId, token, errorMsg) in
                guard let self = self else { return }
                if let errorMsg = errorMsg  {
                    Log.errorText(text: errorMsg, tag: logTag)
                    showAlertVC()
                    return
                }
                mccManager.initRtcEngine()
                mccManager.joinChannel()
                self.mccManager.initMccEx(pid: Config.pid,
                                          pKey: Config.pKey,
                                          token: token,
                                          userId: userId)
            }
        }
    }
    
    private func setupUI() {
        view.addSubview(mainView)
        Log.info(text: "setupUI", tag: logTag)
        mainView.frame = view.bounds
        mainView.karaokeView.scoringView.showDebugView = true
    }
    
    private func commonInit() {
        Log.info(text: "commonInit", tag: logTag)
        mainView.delegate = self
        mainView.karaokeView.delegate = self
        mccManager.delegate = self
        progressProvider.delegate = self
    }
    
    private func setLyricToView() {
        Log.info(text: "setLyricToView", tag: logTag)
        let model = self.lyricModel!
        mainView.karaokeView.setLyricData(data: noLyric ? nil : model)
        mainView.gradeView.setTitle(title: "\(model.name)-\(model.singer)")
    }
    
    private func resetView() {
        Log.info(text: "resetView", tag: logTag)
        mainView.karaokeView.reset()
        mainView.gradeView.reset()
        mainView.incentiveView.reset()
    }
    
    private func showAlertVC() {
        let alertVC = UIAlertController(title: "获取权限失败",
                                        message: "请检查网络连接",
                                        preferredStyle: .alert)
        let action = UIAlertAction(title: "确定",
                                   style: .default,
                                   handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        alertVC.addAction(action)
        present(alertVC, animated: true, completion: nil)
    }
}

// MARK: - RTCManagerDelegate
extension MainTestVC: MCCManagerDelegate {
    func onMccExInitialize(_ manager: MCCManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            songId = mccManager.getInternalSongCode(songId: songId)
            mccManager.createMusicPlayer()
            mccManager.preload(songId: songId)
        }
    }
    
    func onProloadMusic(_ manager: MCCManager, songId: Int, lyricData: Data, pitchData: Data) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let model = KaraokeView.parseLyricData(krcFileData: lyricData,
                                                   pitchFileData: pitchData,
                                                   includeCopyrightSentence: false)
            self.lyricModel = model
            setLyricToView()
            if !self.noLyric {
                manager.startScore(songId: songId)
            }
            else {
                manager.open(songId: songId)
            }
        }
    }
    
    func onMccExScoreStart(_ manager: MCCManager) {
        manager.open(songId: songId)
    }
    
    func onOpenMusic(_ manager: MCCManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            canUseParamsSet = true
            progressProvider.start()
            manager.playMusic()
        }
    }
    
    func onPitch(_ songCode: Int, data: AgoraRawScoreData) {
        guard !isSeeking else {
            return
        }
        let progressGap = calculateProgressGap_debug(progressInMs: data.progressInMs)
        var displayText = "speakerPitch:\(data.speakerPitch) \npitchScore:\(data.pitchScore) \nprogressInMs:\(data.progressInMs)"
        if (progressGap > 50) {
            displayText += "\nprogressGap:\(progressGap)"
        }
        if progressGap < 0 {
            displayText += "gap < 0!!!"
        }

        logOnPitchInvokeGap_debug()
        logNInvalidSpeakPitch_debug(data: data)
        
        if data.speakerPitch < 0 {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            mainView.setConsoleText(displayText)
        }

        mainView.karaokeView.setPitch(speakerPitch: Double(data.speakerPitch),
                                      progressInMs: UInt(data.progressInMs))
    }

    func onLineScore(_ songCode: Int, value: AgoraLineScoreData) {
        guard !noLyric else {
            return
        }
        let score = Int(value.linePitchScore)
        let cumulativeScore = Int(value.cumulativeTotalLinePitchScores)
        let totalScore = value.performedTotalLines * 100
        mainView.lineScoreView.showScoreView(score: score)
        mainView.incentiveView.show(score: score)
        mainView.gradeView.setScore(cumulativeScore: cumulativeScore,
                                    totalScore: Int(totalScore))

    }
}

extension MainTestVC: ProgressProviderDelegate {
    func progressProviderGetPlayerPosition(_ provider: ProgressProvider) -> UInt? {
        let value = mccManager.getMPKCurrentPosition()
        if value < 0 { return nil }
        return UInt(value)
    }
    
    func progressProvider(_ provider: ProgressProvider, shouldSend postion: UInt) {
        
    }
    
    func progressProvider(_ provider: ProgressProvider, didUpdate progressInMs: UInt) {
        mainView.karaokeView.setProgress(progressInMs: progressInMs)
    }
}

// MARK: - MainViewDelegate
extension MainTestVC: MainViewDelegate, KaraokeDelegate {
    func mainView(_ mainView: MainView, onAction: MainView.Action) {
        switch onAction {
        case .skip:
            Log.info(text: "skip", tag: self.logTag)
            mccManager.seek(position: lyricModel.preludeEndPosition)
            progressProvider.seek(position: lyricModel.preludeEndPosition)
        case .pause:
            Log.info(text: "pause", tag: self.logTag)
            mccManager.pauseScore()
            mccManager.pauseMusic()
            progressProvider.pause()
        case .set:
            guard canUseParamsSet else {
                return
            }
            let vc = ParamSetVC()
            vc.delegate = self
            vc.modalPresentationStyle = .pageSheet
            present(vc, animated: true)
        case .change:
            Log.info(text: "change", tag: self.logTag)
            resetView()
        case .quick:
            Log.info(text: "change", tag: self.logTag)
            mccManager.pauseScore()
            mccManager.stopMusic()
            mccManager.leaveChannel()
            progressProvider.stop()
            resetView()
            navigationController?.popViewController(animated: true)
        }
    }
    
    func onKaraokeView(view: KaraokeView, didDragTo position: UInt) {
        isSeeking = true
        mccManager.seek(position: position)
        updateLastProgressInMs_debug(progressInMs: position)
        progressProvider.seek(position: position)
        isSeeking = false
    }
}

// MARK: - ParamSetVCDelegate
extension MainTestVC: ParamSetVCDelegate {
    func didSetParam(param: Param, noLyric: Bool) {
        self.noLyric = noLyric
        
        mccManager.stopMusic()
        mccManager.pauseScore()
        progressProvider.stop()
        
        mainView.karaokeView.reset()
        mainView.incentiveView.reset()
        mainView.gradeView.reset()
        mainView.updateView(param: param)
        
        mccManager.preload(songId: songId)
    }
}
