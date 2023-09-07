//
//  QiangChangScoringVC.swift
//  Demo
//
//  Created by ZYP on 2023/9/1.
//

import UIKit
import AgoraLyricsScore

class QiangChangScoringVC: UIViewController {
    private let qiangChangScoringView = QiangChangScoringView()
    private var timer = GCDTimer()
    private var timeCount = 40
    private let rtcManager = RTCManager()
    var songs = [Song]()
    var song: Song!
    var isQiang = false
    var currentIndex = 0
    let k = KaraokeView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        songs = [
            Song(refSongName: "桃花诺-原唱干声.wav",
                 refPitchName: "桃花诺-原唱干声.pitch",
                 lyrics: "一寸土 一年木 一花一树一贪图\n情是种 爱偏开在迷途\n忘前路 忘旧物 忘心忘你忘最初\n花斑斑 留在爱你的路",
                 name: "桃花诺"),
            Song(refSongName: "反方向的钟-原唱干声.wav",
                 refPitchName: "反方向的钟-原唱干声.pitch",
                 lyrics: "穿梭时间的画面的钟\n从反方向 开始移动\n回到当初爱你的时空\n停格内容 不忠\n所有回忆对着我进攻\n我的伤口 被你拆封\n誓言太沉重泪被纵容\n脸上汹涌 失控",
                 name: "反方向的钟")
        ]
        
        setupUI()
        commonInit()
        rtcManager.initEngine()
        rtcManager.initMCC()
        rtcManager.joinChannel()
        handleQie()
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if parent == nil {
            rtcManager.destory()
        }
    }
    
    deinit {
        KaraokeView.log(text: "QiangChangScoringVC deinit")
    }
    
    private func setupUI() {
        view.addSubview(qiangChangScoringView)
        qiangChangScoringView.frame = view.bounds
    }
    
    private func commonInit() {
        qiangChangScoringView.delegate = self
        rtcManager.delegate = self
    }
    
    fileprivate func handleQiang() {
        isQiang = true
        rtcManager.stop()
        rtcManager.startRecord()
        rtcManager.enableMic(enable: true)
        timer.scheduledMillisecondsTimer(withName: "QiangChangScoringVC",
                                         countDown: 1000000,
                                         milliseconds: 1000,
                                         queue: .main) { [weak self](_, _) in
            guard let self = self else { return }
            timeCount -= 1
            
            if timeCount % 4 == 0 { /** 4s检测一次 **/
                handleOk(isStop: false)
            }
            
            if timeCount > 0 {
                qiangChangScoringView.updateOkTime(num: timeCount)
                return
            }
            
            if timeCount <= 0 {
                handleOk(isStop: true)
            }
            
        }
    }
    
    fileprivate func handleOk(isStop: Bool) {
        if isStop {
            timer.destoryAllTimer()
            timeCount = 40
            isQiang = false
            rtcManager.enableMic(enable: false)
        }
        
        let pcmData = rtcManager.getPcmData()
        let wavData = ScoreClaculator.convertPCMToWAV(pcmData: pcmData)
        ScoreClaculator.recognize(byData: wavData, title: song.name, completedHandler: { (score, error) in
            DispatchQueue.main.async { [weak self] in
                if let err = error as? LocalizedError {
                    self?.qiangChangScoringView.setScore(string: err.localizedDescription, color: .red)
                    return
                }
                
                let string = "score: \(score!)"
                self?.qiangChangScoringView.setScore(string: string)
                
                if score! > 0.6 {
                    self?.timer.destoryAllTimer()
                    self?.timeCount = 40
                    self?.isQiang = false
                    self?.rtcManager.enableMic(enable: false)
                    self?.qiangChangScoringView.setCompleted()
                }
            }
        })
    }
    
    fileprivate func handleQie() {
        song = songs[currentIndex]
        title = song.refPitchName
        qiangChangScoringView.setLiric(text: song.lyrics)
        qiangChangScoringView.setScore(string: "--")
        rtcManager.stop()
        let _ = rtcManager.stopRecord()
        isQiang = false
        rtcManager.enableMic(enable: false)
        let path = Bundle.main.path(forResource: song.refSongName, ofType: nil)!
        rtcManager.open(url: path)
        
        if currentIndex == songs.count - 1 {
            currentIndex = 0
        }
        else {
            currentIndex += 1
        }
    }
    
    private func parse(pitchFileString: String) -> [Double] {
        if pitchFileString.contains("\r\n") {
            let array = pitchFileString.split(separator: "\r\n").map({ Double($0)! })
            return array
        }
        else {
            let array = pitchFileString.split(separator: "\n").map({ Double($0)! })
            return array
        }
    }
    
    var time: CFAbsoluteTime = 0
}

extension QiangChangScoringVC: QiangChangScoringViewDelegate {
    func qiangChangScoringViewDidTap(action: QiangChangScoringView.Action) {
        switch action {
        case .qiang:
            handleQiang()
            break
        case .ok:
            handleOk(isStop: true)
            break
        case .qie:
            handleQie()
            break
        }
    }
}

extension QiangChangScoringVC: RTCManagerDelegate {
    func RTCManagerDidOccurEvent(event: String) {}
    func RTCManagerDidGetLyricUrl(lyricUrl: String) {}
    func RTCManagerDidOpenCompleted() {}
    func RTCManagerDidChangedTo(position: Int) {}
    
}

extension QiangChangScoringVC {
    struct Song {
        let refSongName: String
        let refPitchName: String
        let lyrics: String
        let name: String
    }
}
