//
//  ViewController.swift
//  AgoraKaraokeScore
//
//  Created by zhaoyongqiang on 2021/12/9.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    private lazy var lrcScoreView: AgoraLrcScoreView = {
        let lrcScoreView = AgoraLrcScoreView(delegate: self)
        let config = AgoraLrcScoreConfigModel()
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
        return lrcScoreView
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("播放", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.addTarget(self, action: #selector(clickResetButton(sender:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var replayButton: UIButton = {
        let button = UIButton()
        button.setTitle("重唱", for: .normal)
        button.setTitleColor(.systemPink, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.addTarget(self, action: #selector(clickScrollButton), for: .touchUpInside)
        return button
    }()
    private lazy var scoreLabel: UILabel = {
        let label = UILabel()
        label.textColor = .brown
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private var timer = GCDTimer()
    let lrcUrl = "https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/meta/demo/fulldemoStatic/privacy/005.xml"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        lrcScoreView.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lrcScoreView)
        view.addSubview(resetButton)
        view.addSubview(replayButton)
        lrcScoreView.downloadDelegate = self
        lrcScoreView.scoreDelegate = self
        lrcScoreView.delegate = self
        lrcScoreView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        lrcScoreView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        lrcScoreView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        lrcScoreView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        resetButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        
        resetButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        resetButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)
        scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        scoreLabel.topAnchor.constraint(equalTo: lrcScoreView.topAnchor, constant: 40).isActive = true
        
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        replayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        replayButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        replayButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        replayButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        setupPlayer(completion: {})
        createData()
    }
    
    private func createData() {
        // 下载歌词
        lrcScoreView.setLrcUrl(url: lrcUrl)
    }
    
    private var audioPlayer: AVAudioPlayer?
    
    private func setupPlayer(completion: @escaping () -> Void) {
        let urlString = "http://mfile-sg.intviu.cn/0AA037D4AE9715EB0588EFF4D51E1675/mix_v1.mp3"
        // 下载Mp3
        AgoraDownLoadManager.manager.downloadMP3(urlString: urlString) { path in
            let url = URL(fileURLWithPath: path ?? "")
            self.audioPlayer = try? AVAudioPlayer(contentsOf: url)
            self.audioPlayer?.rate = 1.0
            self.audioPlayer?.prepareToPlay()
            completion()
        }
    }
    
    @objc
    private func clickResetButton(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            audioPlayer?.play()
        } else {
            audioPlayer?.stop()
            lrcScoreView.stop()
        }

        timer.scheduledMillisecondsTimer(withName: "aaa", countDown: 10000000, milliseconds: 200, queue: .main) { [weak self] _, duration in
            self?.setupTimer()
        }
    }
    
    @objc
    private func clickScrollButton() {
        lrcScoreView.stop()
        lrcScoreView.reset()
        audioPlayer?.stop()
        audioPlayer = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
            self.lrcScoreView.setLrcUrl(url: self.lrcUrl)
        }
    }
    
    private func setupTimer() {
        let voice = Double.random(in: 100...300)
        self.lrcScoreView.setVoicePitch([voice])
    }
}

extension ViewController: AgoraLrcViewDelegate {
    func getPlayerCurrentTime() -> TimeInterval {
        let time = (audioPlayer?.currentTime ?? 0)
        return time
    }
    
    func getTotalTime() -> TimeInterval {
        audioPlayer?.duration ?? 0
    }
    
    func seekToTime(time: TimeInterval) {
        audioPlayer?.currentTime = time
    }

    func agoraWordPitch(pitch: Int, totalCount: Int) {

    }
}

extension ViewController: AgoraLrcDownloadDelegate {
    func beginDownloadLrc(url: String) {
        
    }
    func downloadLrcFinished(url: String) {
        self.lrcScoreView.start()
        self.setupPlayer {
            self.audioPlayer?.play()
        }
    }
    func downloadLrcProgress(url: String, progress: Double) {
        print("下载进度 == \(progress)")
    }
}

extension ViewController: AgoraKaraokeScoreDelegate {
    func agoraKaraokeScore(score: Double, cumulativeScore: Double, totalScore: Double) {
        print("分数: \(score) 累加分: \(cumulativeScore) 总分: \(Int(totalScore))")
    }
}

