//
//  HostVC.swift
//  Demo
//
//  Created by ZYP on 2023/3/22.
//

import AgoraRtcKit
import AgoraLyricsScore
import ScoreEffectUI
import RTMTokenBuilder

class HostVC: UIViewController {
    var agoraKit: AgoraRtcEngineKit!
    let ktvView = KTVView()
    var song = MainTestVC.Item(code: 6625526605291650, name: "123", des: "234", lyricType:0)
    let rtcManager = RTCManager()
    let progressTimer = ProgressTimer()
    var isPause = false
    var cumulativeScore = 0
    var packageNum = 0
    var lyricModel: LyricModel!
    var downloadCompleted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        view.addSubview(ktvView)
        ktvView.translatesAutoresizingMaskIntoConstraints = false
        ktvView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        ktvView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        ktvView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        ktvView.heightAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    func commonInit() {
        ktvView.karaokeView.delegate = self
        rtcManager.delegate = self
        progressTimer.delegate = self
    }
    
    func createData(dic: [String : Any]) -> Data {
        let data = try! JSONSerialization.data(withJSONObject: dic, options: [])
        return data
    }
    
    func download(lyricUrl: String) {
        FileCache.fect(urlString: lyricUrl, reqType: song.lyricType) { progress in
            
        } completion: { (lyricPath, pitchPath) in
            var model: LyricModel?
            let lyricData = try! Data(contentsOf: URL(fileURLWithPath: lyricPath))
            let pitchData = pitchPath != nil ? try! Data(contentsOf: URL(fileURLWithPath: pitchPath!)) : nil
            
            model = KaraokeView.parseLyricData(data: lyricData, pitchFileData: pitchData)!
            self.lyricModel = model
            self.ktvView.karaokeView.setLyricData(data: model)
            if lyricPath.contains(".lrc") {
                self.ktvView.gradeView.setTitle(title: "lrc [lyricType:\(self.song.lyricType.name)]")
            }
            else {
                self.ktvView.gradeView.setTitle(title: "xml \(model!.name) - \(model!.singer) [lyricType:\(self.song.lyricType.name)]")
            }
            
            self.downloadCompleted = true
            print("downloadCompleted")
            if !self.rtcManager.openCompleted { return }
            self.rtcManager.play()
            self.progressTimer.start()
        } fail: { error in
            print("fect fail")
        }
    }
}

extension HostVC: RTCManagerDelegate, ProgressTimerDelegate {
    func RTCManagerDidChangedTo(position: Int) {
        
    }
    
    func RTCManagerDidOccurEvent(event: String) {
        print("[demo] \(event)")
    }
    
    func RTCManagerDidGetLyricUrl(lyricUrl: String) {
        download(lyricUrl: lyricUrl)
    }
    
    func RTCManagerDidOpenCompleted() {
        guard downloadCompleted else {
            return
        }
        self.rtcManager.play()
        self.progressTimer.start()
    }
    
    func RTCManagerDidUpdatePitch(pitch: Double) {
        guard !isPause else {
            return
        }
        self.packageNum += 1
        let dict: [String : Any] = ["type": 1, "pitch": pitch, "packageNum" : self.packageNum]
        let data = createData(dic: dict)
        rtcManager.sendData(data: data)
        ktvView.karaokeView.setPitch(pitch: pitch)
    }
    
    func progressTimerGetPlayerPosition() -> Int {
        rtcManager.getPosition()
    }
    
    func progressTimerDidUpdateProgress(progress: Int) {
        ktvView.karaokeView.setProgress(progress: progress)
    }
}

extension HostVC: KaraokeDelegate {
    func onKaraokeView(view: KaraokeView, didFinishLineWith model: LyricLineModel, score: Int, cumulativeScore: Int, lineIndex: Int, lineCount: Int) {
        ktvView.lineScoreView.showScoreView(score: score)
        self.cumulativeScore = cumulativeScore
        ktvView.gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: lineCount * 100)
        ktvView.incentiveView.show(score: score)
    }
}
