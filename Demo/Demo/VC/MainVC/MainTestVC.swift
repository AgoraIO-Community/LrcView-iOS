//
//  MainTestController.swift
//  Demo
//
//  Created by ZYP on 2023/1/30.
//

import UIKit
import AgoraRtcKit
import RTMTokenBuilder
import AgoraLyricsScore
import ScoreEffectUI
import SVProgressHUD

extension MainTestVC {
    struct Item {
        let code: Int
        let isXML: Bool
    }
}

class MainTestVC: UIViewController {
    let lyricsFileDownloader = LyricsFileDownloader()
    let mainView = MainView(frame: .zero)
    let mccManager = MccManager()
    private let songSourceProvider = SongSourceProvider(sourceType: .useForMcc)
    private let progressProvider = ProgressProvider()
    var song: Song!
    var currentSongIndex = 0
    private var timer = GCDTimer()
    var cumulativeScore = 0
    var lyricModel: LyricModel!
    var noLyric = false
    var isPause = false
    var lyricFileType: AgoraMusicContentCenter.LyricFileType = .xml
    fileprivate let logTag = "MainTestVC"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        mccManager.stopMusic()
        mccManager.leaveChannel()
        progressProvider.stop()
        resetView()
    }
    
    func setupUI() {
        view.addSubview(mainView)
        mainView.frame = view.bounds
    }
    
    func commonInit() {
        song = songSourceProvider.getNextSong()
        mainView.delegate = self
        mainView.karaokeView.delegate = self
        lyricsFileDownloader.delegate = self
        progressProvider.delegate = self
        mccManager.delegate = self
        mccManager.initEngine()
        mccManager.joinChannel()
        mccManager.initMCC()
        mccManager.preload(songCode: song.id)
    }
    
    private func setLyricToView() {
        Log.info(text: "setLyricToView", tag: logTag)
        let model = self.lyricModel!
        if !self.noLyric {
            let canScoring = model.hasPitch
            if canScoring { /** xml **/
                self.mainView.karaokeView.setLyricData(data: model, usingInternalScoring: true)
                self.mainView.gradeView.setTitle(title: "\(model.name) - \(model.singer)")
            }
            else {/** lrc **/
                self.mainView.karaokeView.setLyricData(data: model, usingInternalScoring: true)
            }
        }
        else { /** no Lyric **/
            self.mainView.karaokeView.setLyricData(data: nil, usingInternalScoring: true)
            self.mainView.gradeView.isHidden = true
        }
    }
    
    fileprivate func resetView() {
        Log.info(text: "resetView", tag: logTag)
        mainView.karaokeView.reset()
        mainView.gradeView.reset()
        mainView.incentiveView.reset()
    }
}

// MARK: - KaraokeDelegate, MainViewDelegate
extension MainTestVC: KaraokeDelegate, MainViewDelegate {
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
                mccManager.resumeMusic()
                progressProvider.resume()
            }
            else {
                mccManager.pauseMusic()
                progressProvider.pause()
            }
            isPause = !isPause
        case .set:
            let vc = ParamSetVC()
            vc.noPitchFileButton.isHidden = true
            vc.delegate = self
            vc.modalPresentationStyle = .pageSheet
            present(vc, animated: true)
        case .change:
            Log.info(text: "change", tag: self.logTag)
            progressProvider.stop()
            mccManager.stopMusic()
            resetView()
            song = songSourceProvider.getNextSong()
            mccManager.preload(songCode: song.id)
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
        /// drag正在进行的时候, 不会更新内部的progress, 这个时候设置一个last值，等到下一个定时时间到来的时候，把这个last的值-250后送入组建
        progressProvider.seek(position: position + 250)
        mccManager.seek(position: position)
        cumulativeScore = view.scoringView.getCumulativeScore()
        mainView.gradeView.setScore(cumulativeScore: cumulativeScore,
                                    totalScore: lyricModel.lines.count * 100)
    }
    
    func onKaraokeView(view: KaraokeView,
                       didFinishLineWith model: LyricLineModel,
                       score: Int,
                       cumulativeScore: Int,
                       lineIndex: Int,
                       lineCount: Int) {
    }
}

// MARK: - MccManagerDelegate
extension MainTestVC: MccManagerDelegate {
    func onLyricInfo(lyricInfo: AgoraLyricInfo?) {
        if let info = lyricInfo {
            let model = LyricModel.instanceByMccLyricInfo(info: info)
            lyricModel = model
            setLyricToView()
        }
    }
    
    func onPitch(rawScoreData: AgoraRawScoreData) {
        mainView.karaokeView.setPitch(speakerPitch: Double(rawScoreData.pitchScore), progressInMs: rawScoreData.progressInMs)
    }
    
    func onLineScore(lineScoreData: AgoraLineScoreData) {
        mainView.lineScoreView.showScoreView(score: Int(lineScoreData.pitchScore))
        self.cumulativeScore = Int(lineScoreData.cumulativePitchScore)
        mainView.gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: Int(lineScoreData.totalLines) * 100)
        mainView.incentiveView.show(score: Int(lineScoreData.pitchScore))
    }
    
    func onJoinedChannel(_ manager: MccManager) {
        
    }
    
    func onPreloadMusic(_ manager: MccManager, songId: Int, errorMsg: String?) {
        if let msg = errorMsg {
            SVProgressHUD.showError(withStatus: "preload: \(msg)")
            return
        }
        
        manager.getLrc(songCode: songId, lyricType: lyricFileType)
    }
    
    func onLyricResult(url: String) {
        let _ = lyricsFileDownloader.download(urlString: url)
    }
    
    func onOpenMusic(_ manager: MccManager) {
        progressProvider.start()
        manager.playMusic()
    }
    
    func onPitch(_ manager: MccManager, pitch: Double) {
        
    }
}

// MARK: - LyricsFileDownloaderDelegate
extension MainTestVC: LyricsFileDownloaderDelegate {
    func onLyricsFileDownloadCompleted(requestId: Int, fileData: Data?, error: DownloadError?) {
        if let data = fileData {
            let model = KaraokeView.parseLyricData(lyricFileData: data)!
            lyricModel = model
            setLyricToView()
            mccManager.openMusic()
        }
        else {
            Log.errorText(text: "onLyricsFileDownloadCompleted fail", tag: logTag)
        }
    }
    
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {}
}

// MARK: - ProgressProviderDelegate
extension MainTestVC: ProgressProviderDelegate {
    func progressProviderGetPlayerPosition(_ provider: ProgressProvider) -> UInt? {
        let value = mccManager.getMPKCurrentPosition()
        if value < 0 { return nil }
        return UInt(value)
    }
    
    func progressProvider(_ provider: ProgressProvider, didUpdate progressInMs: UInt) {
        var positionAfterDelay = progressInMs
        if progressInMs > 250 {
            positionAfterDelay = progressInMs - 250
        }
        mainView.karaokeView.setProgress(progress: positionAfterDelay)
    }
    
    func progressProvider(_ provider: ProgressProvider, shouldSend postion: UInt) {
        /// TDOD: send data by data stream
    }
}

// MARK: - ParamSetVCDelegate
extension MainTestVC: ParamSetVCDelegate {
    func didSetParam(param: Param, noLyric: Bool, noPitchFile: Bool) {
        self.noLyric = noLyric
        lyricFileType = param.otherConfig.lyricFileType
        mccManager.stopMusic()
        progressProvider.stop()
        resetView()
        mainView.updateView(param: param)
        mccManager.preload(songCode: song.id)
    }
}
