//
//  ViewController.swift
//  AgoraKaraokeScore
//
//  Created by zhaoyongqiang on 2021/12/9.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    private var lrcScoreView: AgoraLrcScoreView!
    private let bottomView = BottomView()
    private var timer = GCDTimer()
    private var audioPlayer: AVAudioPlayer?
    let songDown = SongDownloadManager()
    
    let lrcUrl = Bundle.main.path(forResource: "105780", ofType: "xml")!
    let songUrl = Bundle.main.path(forResource: "music", ofType: "mp3")!
    var localSongUrl: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        lrcScoreView = AgoraLrcScoreView(delegate: self)
        let config = AgoraLrcScoreConfigModel()
        config.isHiddenScoreView = false
        let scoreConfig = AgoraScoreItemConfigModel()
        scoreConfig.tailAnimateColor = .yellow
        scoreConfig.scoreViewHeight = 100
        scoreConfig.emitterColors = [.systemPink]
        config.scoreConfig = scoreConfig
        let lrcConfig = AgoraLrcConfigModel()
        lrcConfig.lrcFontSize = .systemFont(ofSize: 15)
        lrcConfig.isHiddenWatitingView = false
        lrcConfig.isHiddenBottomMask = true
        lrcConfig.lrcHighlightFontSize = .systemFont(ofSize: 18)
        lrcConfig.lrcTopAndBottomMargin = 10
        lrcConfig.tipsColor = .white
        lrcConfig.isHiddenSeparator = false
        lrcConfig.separatorLineColor = .yellow
        config.lrcConfig = lrcConfig
        lrcScoreView.config = config
        
        lrcScoreView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lrcScoreView)
        view.addSubview(bottomView)
        
        lrcScoreView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        lrcScoreView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        lrcScoreView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        lrcScoreView.bottomAnchor.constraint(equalTo: bottomView.topAnchor).isActive = true
        
        bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bottomView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func commonInit() {
        bottomView.delegate = self
        lrcScoreView.downloadDelegate = self
        lrcScoreView.scoreDelegate = self
        lrcScoreView.delegate = self
        songDown.delegate = self
        
        songDown.download(urlString: "https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/meta/demo/fulldemoStatic/privacy/music.mp3")
    }
    
    private func initAudioPlayer(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        } catch let error {
            print("\(error)")
            print("")
        }
        audioPlayer?.rate = 1.0
        audioPlayer?.prepareToPlay()
    }
    
    private func setupTimer() {
        let voice = Double.random(in: 0...300)
        lrcScoreView.setVoicePitch([voice])
    }
}

extension ViewController: AgoraLrcViewDelegate, AgoraLrcDownloadDelegate, AgoraKaraokeScoreDelegate {
    func getPlayerCurrentTime() -> TimeInterval {
        let time = (audioPlayer?.currentTime ?? 0) * 1000
        return time
    }
    
    func getTotalTime() -> TimeInterval {
        let time = (audioPlayer?.duration ?? 0) * 1000
        return time
    }
    
    func seekToTime(time: TimeInterval) {
        audioPlayer?.currentTime = time / 1000
    }
    
    func agoraWordPitch(pitch: Int, totalCount: Int) {
        /// 调试用，在真实项目中应该是用rtc相关的回调进行设置
        lrcScoreView.setVoicePitch([Double(pitch)])
    }
    
    func downloadLrcFinished(url: String) {
        bottomView.stopLoading()
        lrcScoreView.start()
        let ret = audioPlayer!.play()
        print("play ret \(ret)")
        let position = lrcScoreView.getFirstToneBeginPosition()
        print("getFirstToneBeginPosition (downloadLrcFinished后) \(position)")
    }
    
    func beginDownloadLrc(url: String) {
        bottomView.startLoading()
    }
    
    func downloadLrcProgress(url: String, progress: Double) {}
    
    func agoraKaraokeScore(score: Double, cumulativeScore: Double, totalScore: Double) {
        print("分数: \(score) 累加分: \(cumulativeScore) 总分: \(Int(totalScore))")
    }
}

extension ViewController: BottomViewDelegate {
    func bottomViewDidTap(actionType: BottomView.ActionType) {
        switch actionType {
        case .play:
            lrcScoreView.setLrcUrl(url: lrcUrl)
            let position = lrcScoreView.getFirstToneBeginPosition()
            print("getFirstToneBeginPosition \(position)")
            break
        case .replay:
            lrcScoreView.stop()
            lrcScoreView.reset()
            lrcScoreView.resetTime()
            audioPlayer?.stop()
            audioPlayer = nil
            
            initAudioPlayer(url: localSongUrl)
            lrcScoreView.setLrcUrl(url: lrcUrl)
            break
        case .skip:
            break
        }
    }
}


extension ViewController: SongDownloadManagerDelegate {
    func songDownloadManagerDidFinished(localUrl: URL) {
        localSongUrl = localUrl
        initAudioPlayer(url: localSongUrl)
        bottomView.enablePlay(enable: true)
    }
}
