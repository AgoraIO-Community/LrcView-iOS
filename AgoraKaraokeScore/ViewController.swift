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
    private let songDownloadManager = SongDownloadManager()
    
//    let lrcUrl = "https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/meta/demo/fulldemoStatic/privacy/005.xml"
    
    let lrcUrl = "https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/meta/demo/fulldemoStatic/privacy/153378.xml"
    
//    let songUrl = "http://mfile-sg.intviu.cn/0AA037D4AE9715EB0588EFF4D51E1675/mix_v1.mp3"
    
    let songUrl = "https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/meta/demo/fulldemoStatic/privacy/65dc0c194ca0e15164738987e5e8459b.mov"
    var lrcDownloadOk = false
    var songDownloadOk = false
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
        songDownloadManager.delegate = self
        
        bottomView.startLoading()
        /// 下载歌曲
        songDownloadManager.download(urlString: songUrl)
    }
    
    private func initAudioPlayer(url: URL) {
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
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
        lrcScoreView.setVoicePitch([Double(pitch)])
    }
    
    func downloadLrcFinished(url: String) {
        lrcDownloadOk = true
        bottomView.stopLoading()
        lrcScoreView.start()
        audioPlayer?.play()
//        timer.scheduledMillisecondsTimer(withName: "aaa", countDown: 10000000, milliseconds: 200, queue: .main) { [weak self] _, duration in
//            self?.setupTimer()
//        }
    }
    
    func beginDownloadLrc(url: String) {
        bottomView.startLoading()
    }
    
    func downloadLrcProgress(url: String, progress: Double) {}
    
    func agoraKaraokeScore(score: Double, cumulativeScore: Double, totalScore: Double) {
        print("分数: \(score) 累加分: \(cumulativeScore) 总分: \(Int(totalScore))")
    }
}

extension ViewController: SongDownloadManagerDelegate {
    func songDownloadManagerDowning(progress: Double) {
        print("下载歌曲进度 \(progress)")
    }
    
    func songDownloadManagerDidFinished(localUrl: URL) {
        print("下载歌曲完成！！")
        localSongUrl = localUrl
        initAudioPlayer(url: localUrl)
        songDownloadOk = true
        bottomView.stopLoading()
        bottomView.enablePlay(enable: true)
    }
}

extension ViewController: BottomViewDelegate {
    func bottomViewDidTap(actionType: BottomView.ActionType) {
        switch actionType {
        case .play:
            lrcScoreView.setLrcUrl(url: lrcUrl)
//            audioPlayer?.play()
//            lrcScoreView.start()
            break
        case .replay:
            lrcScoreView.stop()
            lrcScoreView.reset()
            lrcScoreView.resetTime()
            audioPlayer?.stop()
            audioPlayer = nil
            
            if songDownloadOk {
                initAudioPlayer(url: localSongUrl)
                lrcScoreView.setLrcUrl(url: lrcUrl)
//                lrcScoreView.start()
//                audioPlayer?.play()
            }
            break
        }
    }
}

