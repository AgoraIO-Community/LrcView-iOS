//
//  MainTestVCEx.swift
//  Demo
//
//  Created by ZYP on 2024/4/23.
//

import UIKit
import AgoraLyricsScore
import AgoraRtcKit
import SVProgressHUD

class MainTestVCEx: UIViewController {
    private let mainView = MainView()
    private let mccManager = MccManagerEx()
    /// 用于记录每行的得分（拖拽歌词用到）
    fileprivate let lineScoreRecorder = LineScoreRecorder()
    /// 进度进度校准和进度提供者
    private let progressProvider = ProgressProvider()
    private let songSourceProvider = SongSourceProvider(sourceType: .useForVendor2)
    private var songId: Int?
    private var songIds = [Int]()
    fileprivate var lyricModel: LyricModel!
    let logTag = "MainTestVCEx"
    fileprivate var isSeeking = false
    fileprivate var canUseParamsSet = false
    fileprivate var noLyric = false
    fileprivate var noPitchFile = false
    var isPause = false
    var totalScore: UInt = 0
    var songOffsetBegin: Int = 0
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        mccManager.pauseScore()
        mccManager.stopMusic()
        mccManager.leaveChannel()
        progressProvider.stop()
        resetView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
        
        if let token = Config.token, let userId = Config.userId {
            mccManager.initEngine()
            mccManager.joinChannel()
            mccManager.initMCC(pid: Config.pid,
                                 pKey: Config.pKey,
                                 token: token,
                                 userId: userId)
            mccManager.preload(songCode: "\(songIds.first!)")
        }
        else {
            AccessProvider.fetchAccessData(url: Config.accessUrl) { [weak self](userId, token, errorMsg) in
                guard let self = self else { return }
                if let errorMsg = errorMsg  {
                    Log.errorText(text: errorMsg, tag: logTag)
                    showAlertVC()
                    return
                }
                mccManager.initEngine()
                mccManager.joinChannel()
                self.mccManager.initMCC(pid: Config.pid,
                                        pKey: Config.pKey,
                                        token: token,
                                        userId: userId)
                self.mccManager.preload(songCode: "\(self.songIds.first!)")
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
        songIds = songSourceProvider.songs.map({ $0.id })
    }
    
    private func setLyricToView() {
        Log.info(text: "setLyricToView", tag: logTag)
        let model = self.lyricModel!
        mainView.karaokeView.setLyricData(data: noLyric ? nil : model, usingInternalScoring: false)
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
extension MainTestVCEx: MccManagerExDelegate {
    func onPreloadMusic(_ manager: MccManagerEx,
                        songId: Int,
                        percent: Int,
                        lyricData: Data,
                        pitchData: Data,
                        lyricOffset: Int,
                        songOffsetBegin: Int,
                        errorMsg: String?) {
        let needPitch = !noPitchFile
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.songOffsetBegin = songOffsetBegin
            let model = KaraokeView.parseLyricData(lyricFileData: lyricData,
                                                   pitchFileData: needPitch ? pitchData : nil,
                                                   lyricOffset: lyricOffset,
                                                   includeCopyrightSentence: true)
            lineScoreRecorder.setLyricData(data: model!)
            self.lyricModel = model
            setLyricToView()
            if !self.noLyric {
                manager.startScore()
            }
            else {
                manager.openMusic()
            }
        }
    }
    
    func onLyricResult(url: String) {}
    
    func onMccExScoreStart(_ manager: MccManagerEx) {
        manager.openMusic()
    }
    
    func onOpenMusic(_ manager: MccManagerEx) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            canUseParamsSet = true
            progressProvider.start()
            manager.playMusic()
        }
    }
    
    func onPitch(_ manager: MccManagerEx, rawScoreData: AgoraRawScoreData) {
        guard !isSeeking else {
            return
        }
        let progressGap = calculateProgressGap_debug(progressInMs: rawScoreData.progressInMs)
        var displayText = "speakerPitch:\(rawScoreData.speakerPitch) \npitchScore:\(rawScoreData.pitchScore) \nprogressInMs:\(rawScoreData.progressInMs)"
        if (progressGap > 50) {
            displayText += "\nprogressGap:\(progressGap)"
        }
        if progressGap < 0 {
            displayText += "gap < 0!!!"
        }
        
        logOnPitchInvokeGap_debug()
        logInvalidSpeakPitch_debug(speakerPitch: Int(rawScoreData.speakerPitch))
        
        if rawScoreData.speakerPitch < 0 {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            mainView.setConsoleText(displayText)
        }
        
        mainView.karaokeView.setPitch(speakerPitch: Double(rawScoreData.speakerPitch),
                                      progressInMs: UInt(rawScoreData.progressInMs),
                                      score: UInt(rawScoreData.pitchScore))
    }
    
    func onLineScore(_ songCode: Int, lineScoreData: AgoraLineScoreData) {
        let score = Int(lineScoreData.pitchScore)
        totalScore = UInt(lineScoreData.totalLines * 100)
        mainView.lineScoreView.showScoreView(score: score)
        mainView.incentiveView.show(score: score)
        let cumulativeScore = lineScoreRecorder.setLineScore(index: lineScoreData.index - 1, score: UInt(score))
        mainView.gradeView.setScore(cumulativeScore: Int(cumulativeScore),
                                    totalScore: Int(totalScore))
        mainView.lineScoreView.showScoreView(score: Int(lineScoreData.pitchScore))
        mainView.incentiveView.show(score: Int(lineScoreData.pitchScore))
    }
}

extension MainTestVCEx: ProgressProviderDelegate {
    func progressProviderGetPlayerPosition(_ provider: ProgressProvider) -> UInt? {
        let value = mccManager.getMPKCurrentPosition()
        if value < 0 { return nil }
        return UInt(value)
    }
    
    func progressProvider(_ provider: ProgressProvider, shouldSend postion: UInt) {
        
    }
    
    func progressProvider(_ provider: ProgressProvider, didUpdate progressInMs: UInt) {
        mainView.karaokeView.setProgress(progress: progressInMs + UInt(songOffsetBegin))
    }
}

// MARK: - MainViewDelegate
extension MainTestVCEx: MainViewDelegate, KaraokeDelegate {
    func mainView(_ mainView: MainView, onAction: MainView.Action) {
        switch onAction {
        case .skip:
            Log.info(text: "skip", tag: self.logTag)
            if lyricModel == nil { return }
            var position = lyricModel.preludeEndPosition
            if position > 1000 {
                position -= 1000
            }
            mccManager.seek(position: position)
            progressProvider.seek(position: position)
        case .pause:
            Log.info(text: "pause", tag: self.logTag)
            if isPause {
                mccManager.resumeScore()
                mccManager.resumeMusic()
                progressProvider.resume()
            }
            else {
                mccManager.pauseScore()
                mccManager.pauseMusic()
                progressProvider.pause()
            }
            isPause = !isPause
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
            progressProvider.stop()
            mccManager.pauseScore()
            mccManager.stopMusic()
            mccManager.stopScore()
            resetView()
            songId = songIds[songSourceProvider.genNextIndex()]
            mccManager.preload(songCode: "\(songId!)")
            break
        case .quick:
            Log.info(text: "quick", tag: self.logTag)
            navigationController?.popViewController(animated: true)
            break
        case .changePlayMode:
            mccManager.resversePlayMode()
            break
        }
    }
    
    func onKaraokeView(view: KaraokeView, didDragTo position: UInt) {
        isSeeking = true
        mccManager.seek(position: position)
        updateLastProgressInMs_debug(progressInMs: position)
        progressProvider.seek(position: position)
        let cumulativeScore = lineScoreRecorder.seek(position: position)
        mainView.gradeView.setScore(cumulativeScore: Int(cumulativeScore),
                                    totalScore: lyricModel.lines.count * 100)
        isSeeking = false
    }
}

// MARK: - ParamSetVCDelegate
extension MainTestVCEx: ParamSetVCDelegate {
    func didSetParam(param: Param, noLyric: Bool, noPitchFile: Bool) {
        self.noLyric = noLyric
        self.noPitchFile = noPitchFile
        progressProvider.stop()
        mccManager.stopMusic()
        mccManager.pauseScore()
        
        mainView.karaokeView.reset()
        mainView.incentiveView.reset()
        mainView.gradeView.reset()
        mainView.updateView(param: param)
        mccManager.setScoreLevel(level: param.karaoke.scoreLevel)
        mccManager.preload(songCode: "\(songId!)")
    }
}
