//
//  AVPlayerTestVC.swift
//  Demo
//
//  Created by ZYP on 2022/12/23.
//

import UIKit
import AgoraRtcKit
import RTMTokenBuilder
import AgoraLyricsScore
import AVFoundation

class AVPlayerTestVC: UIViewController {
    let karaokeView = KaraokeView()
    private var audioPlayer: AVAudioPlayer?
    let lrcUrl = Bundle.main.path(forResource: "105780", ofType: "xml")!
    let songUrl = Bundle.main.path(forResource: "music", ofType: "mp3")!
    private var timer = GCDTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        view.addSubview(karaokeView)
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    func commonInit() {
        let data = try! Data(contentsOf: URL(fileURLWithPath: lrcUrl))
        let model = KaraokeView.parseLyricData(data: data)!
        karaokeView.setLyricData(data: model)
        initAudioPlayer(url:URL(fileURLWithPath: songUrl))
        let ret = audioPlayer!.play()
        print("play ret \(ret)")
        
        
        
        timer.scheduledMillisecondsTimer(withName: "AVPlayerTestVC",
                                         countDown: 1000000,
                                         milliseconds: 50,
                                         queue: .main) { [weak self](_, time) in
            guard let self = self else { return }
            if let currentTime = self.audioPlayer?.currentTime {
//                self.karaokeView.setProgress(progress: Int(currentTime * 1000) )
            }
        }
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}
