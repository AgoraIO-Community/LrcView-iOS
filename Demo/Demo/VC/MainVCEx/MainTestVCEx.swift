//
//  MainTestVCEx.swift
//  Demo
//
//  Created by ZYP on 2024/4/23.
//

import UIKit
import AgoraLyricsScore
import AgoraRtcKit
import AgoraMccExService
import SVProgressHUD

class MainTestVCEx: UIViewController {
    /// 主视图
    private let mainView = MainView()
    /// MusicContentConter 管理实例
    private let mccManager = MccManagerEx()
    fileprivate let lineScoreRecorder = LineScoreRecorder()
    /// 进度进度校准和进度提供者
    private let progressProvider = ProgressProvider()
    private var songId: Int?
    private var songIds = [Int]()
    private let songSourceProvider = SongSourceProvider(sourceType: .useForMccEx)
    var lyricModel: LyricModel!
    let logTag = "MainTestVCEx"
    fileprivate var isSeeking = false
    fileprivate var canUseParamsSet = false
    fileprivate var noLyric = false
    fileprivate var noPitchFile = false
    /// 是否暂停
    var isPause = false
    var totalScore: UInt = 0
    var songOffsetBegin: Int = 0
    /// 七里香 972295
    /// 明月几时有：239038150
    /// 十年 40289835
    
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
extension MainTestVCEx: MccManagerDelegateEx {
    func onMccExInitialize(_ manager: MccManagerEx) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            songIds = songIds.map({ [weak self] in
                guard let self = self else {
                    return $0
                }
                return self.mccManager.getInternalSongCode(songId: $0)
            })
            songId = songIds.first
            mccManager.createMusicPlayer()
            mccManager.preload(songId: songId!)
        }
    }
    
    func onPreloadMusic(_ manager: MccManagerEx,
                        songId: Int,
                        lyricData: Data,
                        pitchData: Data,
                        percent: Int,
                        lyricOffset: Int,
                        songOffsetBegin: Int,
                        errMsg: String?) {
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
                manager.startScore(songId: songId)
            }
            else {
                manager.open(songId: songId)
            }
        }
    }
    
    func onMccExScoreStart(_ manager: MccManagerEx) {
        manager.open(songId: songId!)
    }
    
    func onOpenMusic(_ manager: MccManagerEx) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            canUseParamsSet = true
            progressProvider.start()
            manager.playMusic()
        }
    }
    
    func onPitch(_ songCode: Int, data: AgoraRawScoreDataEx) {
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

    func onLineScore(_ songCode: Int, value: AgoraLineScoreDataEx) {
        guard !noLyric else {
            return
        }
        let score = Int(value.linePitchScore)
        totalScore = UInt(value.performedTotalLines * 100)
        mainView.lineScoreView.showScoreView(score: score)
        mainView.incentiveView.show(score: score)
        let cumulativeScore = lineScoreRecorder.setLineScore(index: value.performedLineIndex - 1, score: UInt(score))
        mainView.gradeView.setScore(cumulativeScore: Int(cumulativeScore),
                                    totalScore: Int(totalScore))
        SVProgressHUD.setOffsetFromCenter(.init(horizontal: 0, vertical: 1 * (view.bounds.height/2 - 60)))
        SVProgressHUD.showInfo(withStatus: "i:\(value.performedLineIndex - 1) s:\(score)")
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
            resetView()
            songId = songIds[songSourceProvider.genNextIndex()]
            mccManager.preload(songId: songId!)
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
                                    totalScore: Int(totalScore))
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
        
        mccManager.preload(songId: songId!)
    }
}
