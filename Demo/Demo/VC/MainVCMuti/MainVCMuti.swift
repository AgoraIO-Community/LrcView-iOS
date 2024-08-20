//
//  MainVCMuti.swift
//  Demo
//
//  Created by ZYP on 2024/8/2.
//

import UIKit
import AgoraRtcKit
import RTMTokenBuilder
import AgoraLyricsScore
import ScoreEffectUI
import SVProgressHUD

extension MainVCMuti {
    struct Item {
        let code: Int
        let isXML: Bool
    }
}

class MainVCMuti: UIViewController {
    let lyricsFileDownloader = LyricsFileDownloader()
    let mainView = MainView(frame: .zero)
    let mccManager = MccManagerMuti()
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
    fileprivate let logTag = "MainVCMuti"
    
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
                self.mainView.karaokeView.setLyricData(data: model, usingInternalScoring: false)
                self.mainView.gradeView.setTitle(title: "\(model.name) - \(model.singer)")
            }
            else {/** lrc **/
                self.mainView.karaokeView.setLyricData(data: model, usingInternalScoring: false)
            }
        }
        else { /** no Lyric **/
            self.mainView.karaokeView.setLyricData(data: nil, usingInternalScoring: false)
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
extension MainVCMuti: KaraokeDelegate, MainViewDelegate {
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
        cumulativeScore = Int(mccManager.getCumulativeScoreData().cumulativePitchScore)
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
extension MainVCMuti: MccManagerMutiDelegate {
    func onLyricResult(url: String) {
        let _ = lyricsFileDownloader.download(urlString: url)
    }
    
    func onJoinedChannel(_ manager: MccManagerMuti) {
        
    }
    
    func onPreloadMusic(_ manager: MccManagerMuti, songId: Int, errorMsg: String?) {
        if let msg = errorMsg {
            SVProgressHUD.showError(withStatus: "preload: \(msg)")
            return
        }
        
        manager.getLrc(songCode: songId, lyricType: lyricFileType)
    }
    
    func onOpenMusic(_ manager: MccManagerMuti) {
        manager.playMusic()
        manager.startScore()
        progressProvider.start()
    }
    
    func onLyricInfo(lyricInfo: AgoraLyricInfo?) {
        if let info = lyricInfo {
            let model = LyricModel.instanceByMccLyricInfo(info: info)
            lyricModel = model
            setLyricToView()
        }
    }
    
    func onPitch(rawScoreData: AgoraRawScoreData) {
        var positionAfterDelay = rawScoreData.progressInMs
        if rawScoreData.progressInMs > 250 {
            positionAfterDelay = rawScoreData.progressInMs - 250
        }
        mainView.karaokeView.setPitch(speakerPitch: Double(rawScoreData.speakerPitch),
                                      progressInMs: positionAfterDelay,
                                      score: UInt(rawScoreData.pitchScore))
    }
    
    func onLineScore(lineScoreData: AgoraLineScoreData) {
        mainView.lineScoreView.showScoreView(score: Int(lineScoreData.pitchScore))
        self.cumulativeScore = Int(lineScoreData.cumulativePitchScore)
        mainView.gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: Int(lineScoreData.totalLines) * 100)
        mainView.incentiveView.show(score: Int(lineScoreData.pitchScore))
    }
    
}

// MARK: - LyricsFileDownloaderDelegate
extension MainVCMuti: LyricsFileDownloaderDelegate {
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
extension MainVCMuti: ProgressProviderDelegate {
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
extension MainVCMuti: ParamSetVCDelegate {
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
