//
//  MainTestVC2.swift
//  Demo
//
//  Created by ZYP on 2024/4/23.
//

import UIKit
import AgoraLyricsScore
import AgoraRtcKit

class MainTestVC2: UIViewController {
    private let mainView = MainView()
    private var rtcManager: RTCManager!
    private let progressProvider = ProgressProvider()
    private let songId = 6625526605291650
    var lyricModel: LyricModel!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        rtcManager = RTCManager()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
        rtcManager.initEngine()
        rtcManager.joinChannel()
        rtcManager.initMCC()
        rtcManager.createMusicPlayer()
        rtcManager.preload(songId: songId)
    }
    
    private func setupUI() {
        view.addSubview(mainView)
        mainView.frame = view.bounds
        mainView.karaokeView.scoringView.showDebugView = true
    }
    
    private func commonInit() {
        mainView.delegate = self
        rtcManager.delegate = self
        progressProvider.delegate = self
    }
    
    private func setLyricToView() {
        let info = rtcManager.getLyricInfo(songId: songId)
        let lines = info.sentences.map({ LyricLineModel(beginTime: Int($0.begin), duration: Int($0.duration), content: $0.content, tones:$0.words.map({ LyricToneModel(beginTime: Int($0.begin), duration: Int($0.duration), word: $0.word, pitch: $0.refPitch, lang: .zh, pronounce: "") })) })
        let model = LyricModel(name: info.name,
                               singer: info.singer,
                               type: .slow,
                               lines: lines,
                               preludeEndPosition: Int(info.preludeEndPosition),
                               duration: Int(info.duration),
                               hasPitch: info.hasPitch)
        mainView.karaokeView.setLyricData(data: model)
        mainView.gradeView.setTitle(title: "\(info.name)-\(info.singer)")
    }
    
    private func resetView() {
        mainView.karaokeView.reset()
        mainView.gradeView.reset()
        mainView.incentiveView.reset()
    }
    
    var lastPitchTime:CFAbsoluteTime = 0
    var lastProgressInMs = 0
}

// MARK: - RTCManagerDelegate
extension MainTestVC2: RTCManagerDelegate {
    func rtcManager(_ manager: RTCManager, didProloadMusicWithSongId: Int) {
        manager.open(songId: songId)
    }
    
    func rtcManagerDidOpenMusic(_ manager: RTCManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            setLyricToView()
            manager.playMusic()
            manager.startScore(songId: songId)
            progressProvider.startTime()
        }
    }
    
    func rtcManager(_ manager: RTCManager, didReceivePitch pitch: Double) {
        /// opt for setting fake machine
        if manager.useFakeScoringMachine {
            manager.fakeScoringMachine?.pushPitch(pitch: pitch)
        }
    }
    
    func onPitch(_ songCode: Int, item: AgoraRawScoreData) {
        let progressGap = Int(item.progressInMs) - lastProgressInMs
        lastProgressInMs = Int(item.progressInMs)
        
        var displayText = "speakerPitch:\(item.speakerPitch) \npitchScore:\(item.pitchScore) \nprogressInMs:\(item.progressInMs)"
        if (progressGap > 50) {
            displayText += "\nprogressGap:\(progressGap)"
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let gap = startTime - lastPitchTime
        lastPitchTime = startTime
        if (gap > 0.1) {
            print("> gap:[\(gap.keep3)] \(item.speakerPitch)")
        }
        else {
            print("gap:[\(gap.keep3)] \(item.speakerPitch)")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            mainView.setConsoleText(displayText)
        }
        
        if (item.speakerPitch < 0) {
            print("")
        }
        
        mainView.karaokeView.setPitch(speakerPitch: Double(item.speakerPitch),
                                      pitchScore: item.pitchScore,
                                      progressInMs: Int(item.progressInMs))
    }
    
    func onLineScore(_ songCode: Int, value: AgoraCumulativeScoreData) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            let score = Int(value.performedLinePitchScore)
            let cumulativeScore = Int(value.cumulativeTotalLinePitchScores)
            let totalScore = value.performedTotalLines * 100
            mainView.lineScoreView.showScoreView(score: score)
            mainView.incentiveView.show(score: score)
            mainView.gradeView.setScore(cumulativeScore: cumulativeScore,
                                        totalScore: Int(totalScore))
        }
        
    }
    
    func onCumulativeScore(_ songCode: Int, value: AgoraCumulativeScoreData) {
        
    }
    
    func onLyricInfo(_ songCode: Int, lyricInfo: AgoraLyricInfo) {
        
    }
}

extension MainTestVC2: ProgressProviderDelegate {
    func progressProviderGetPlayerPosition(_ provider: ProgressProvider) -> Int {
        rtcManager.getMPKCurrentPosition()
    }
    
    func progressProvider(_ provider: ProgressProvider, shouldSend postion: Int) {
        
    }
    
    func progressProvider(_ provider: ProgressProvider, didUpdate progressInMs: Int) {
        /// opt for setting fake machine
        if rtcManager.useFakeScoringMachine {
            rtcManager.fakeScoringMachine?.setProgress(progressInMs: progressInMs)
        }
        mainView.karaokeView.setProgress(progressInMs: progressInMs)
    }
}

// MARK: - MainViewDelegate
extension MainTestVC2: MainViewDelegate {
    func mainView(_ mainView: MainView, onAction: MainView.Action) {
        switch onAction {
        case .skip:
            print("skip")
            if let preludeEndPosition = rtcManager.skipMusicPrelude() {
                progressProvider.skip(progress: preludeEndPosition)
            }
        case .pause:
            print("pause")
            rtcManager.pauseScore()
            rtcManager.pauseMusic()
            progressProvider.pause()
        case .set:
            let vc = ParamSetVC()
            vc.delegate = self
            vc.modalPresentationStyle = .pageSheet
            present(vc, animated: true)
        case .change:
            resetView()
            print("change")
        case .quick:
            progressProvider.pause()
            rtcManager.pauseScore()
            rtcManager.stopMusic()
            rtcManager.leaveChannel()
            progressProvider.stop()
            mainView.karaokeView.reset()
            mainView.gradeView.reset()
            mainView.incentiveView.reset()
            navigationController?.popViewController(animated: true)
            print("quick")
        }
    }
}

// MARK: - ParamSetVCDelegate
extension MainTestVC2: ParamSetVCDelegate {
    func didSetParam(param: Param, noLyric: Bool) {
        mainView.updateView(param: param)
    }
}
