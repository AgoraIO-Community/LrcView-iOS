//
//  MainTestVC.swift
//  Demo
//
//  Created by ZYP on 2023/7/3.
//

import AgoraLyricsScore
import AgoraRtcKit

class MainTestVC: UIViewController {
    let ktvView = KTVView()
    let panelView = PanelView()
    let rtcManager = RTCManager()
    let progressTimer = ProgressTimer()
    var downloadCompleted = false
    var currentSongIndex = 0
    var cumulativeScore = 0
    var noLyric = false
    var lyricModel: LyricModel?
    var song: Item!
    var songs = [
        Item(code: 6246262727289260, name: "from玉成1", des: "", lyricType: 4),
        Item(code: 6246262727289101, name: "from玉成2", des: "", lyricType: 4),
        Item(code: 6246262727286610, name: "from玉成3", des: "", lyricType: 4),
        Item(code: 6246262727286510, name: "from玉成4", des: "", lyricType: 4),
        Item(code: 6246262727284460, name: "from玉成5", des: "", lyricType: 4),
        //                 Item(code: 6246262727282260, name: "燕尾蝶", des: "", lyricType: 4),
        //                 Item(code: 6246262727282260, name: "燕尾蝶", des: "", lyricType: 1),
        //                 Item(code: 6843908387781240, name: "须尽欢", des: "", lyricType: 4),
        //                 Item(code: 6843908387781240, name: "须尽欢", des: "", lyricType: 0),
        //                 Item(code: 6625526603631810, name: "简单爱", des: "", lyricType: 3),
        //                 Item(code: 6625526603631810, name: "简单爱", des: "", lyricType: 0),
        //                 Item(code: 6315145508122860, name: "一天到晚游泳的鱼", des: "xml不支持打分", lyricType: 0),
        //                 /** xml 不包含打分 **/
        //                 Item(code: 6315145508122860, name: "纯音乐", des: "", lyricType: 0)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
        song = songs.first
        rtcManager.initEngine()
        rtcManager.initMCC()
        rtcManager.joinChannel()
        //        rtcManager.loadMusic(song: song, getLyrics: true)
    }
    
    func setupUI() {
        view.addSubview(ktvView)
        view.addSubview(panelView)
        
        ktvView.translatesAutoresizingMaskIntoConstraints = false
        panelView.translatesAutoresizingMaskIntoConstraints = false
        
        ktvView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        ktvView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        ktvView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        ktvView.heightAnchor.constraint(equalToConstant: 350).isActive = true
        
        panelView.topAnchor.constraint(equalTo: ktvView.bottomAnchor).isActive = true
        panelView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        panelView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        panelView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    func commonInit() {
        panelView.delegate = self
        rtcManager.delegate = self
        progressTimer.delegate = self
        ktvView.karaokeView.delegate = self
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

extension MainTestVC: PanelViewDelegate, RTCManagerDelegate, ProgressTimerDelegate {
    
    // MARK: - PanelViewDelegate
    
    func panelViewDidTapAction(action: PanelView.Action) {
        switch action {
        case .skip:
            if let model = lyricModel {
                rtcManager.seek(time: max(0, model.preludeEndPosition - 2000))
            }
            break
        case .pause:
            progressTimer.isPause = !progressTimer.isPause
            rtcManager.pause()
            break
        case .quick:
            rtcManager.destory()
            navigationController?.popViewController(animated: true)
            break
        case .set:
            let vc = ParamSetVC()
            vc.delegate = self
            vc.modalPresentationStyle = .pageSheet
            present(vc, animated: true)
            break
        case .change:
            rtcManager.stop()
            progressTimer.reset()
            
            currentSongIndex += 1
            if currentSongIndex >= songs.count {
                currentSongIndex = 0
            }
            song = songs[currentSongIndex]
            
            ktvView.incentiveView.reset()
            ktvView.gradeView.reset()
            ktvView.karaokeView.reset()
            downloadCompleted = false
            rtcManager.loadMusic(song: song, getLyrics: !noLyric)
            break
        case .search:
            let vc = SearchVC()
            vc.setup(rtcManager: rtcManager)
            vc.modalPresentationStyle = .pageSheet
            vc.delegate = self
            present(vc, animated: true)
            break
        }
    }
    
    // MARK: - RTCManagerDelegate
    
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
        guard !noLyric, !progressTimer.isPause else {
            return
        }
        ktvView.karaokeView.setPitch(pitch: pitch)
    }
    
    // MARK: - ProgressTimerDelegate
    
    func progressTimerGetPlayerPosition() -> Int {
        rtcManager.getPosition()
    }
    
    func progressTimerDidUpdateProgress(progress: Int) {
        ktvView.karaokeView.setProgress(progress: progress)
    }
}

extension MainTestVC: ParamSetVCDelegate, SearchVCDelegate, KaraokeDelegate {
    
    // MARK: - SearchVCDelegate
    
    func searchVCDidSelected(music: AgoraMusic, lyricType: Int) {
        let item = Item(code: music.songCode, name: music.name, des: "", lyricType: lyricType)
        song = item
        downloadCompleted = false
        rtcManager.loadMusic(song: song, getLyrics: !noLyric)
    }
    
    // MARK: - ParamSetVCDelegate
    
    func didSetParam(param: Param, noLyric: Bool) {
        self.noLyric = noLyric
        downloadCompleted = noLyric
        ktvView.gradeView.reset()
        ktvView.updateView(param: param)
        if noLyric {
            ktvView.gradeView.setTitle(title: "no-lyric")
            ktvView.karaokeView.scoringEnabled = false
            ktvView.karaokeView.reset()
            ktvView.karaokeView.setLyricData(data: nil)
            ktvView.gradeView.isHidden = true
        }
        else {
            ktvView.gradeView.isHidden = false
        }
        progressTimer.reset()
        rtcManager.loadMusic(song: song, getLyrics: !noLyric)
    }
    
    // MARK: - KaraokeDelegate
    
    func onKaraokeView(view: KaraokeView, didFinishLineWith model: LyricLineModel, score: Int, cumulativeScore: Int, lineIndex: Int, lineCount: Int) {
        ktvView.lineScoreView.showScoreView(score: score)
        self.cumulativeScore = cumulativeScore
        ktvView.gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: lineCount * 100)
        ktvView.incentiveView.show(score: score)
    }
    
    func onKaraokeView(view: KaraokeView, didDragTo position: Int) {
        /// drag正在进行的时候, 不会更新内部的progress, 这个时候设置一个last值，等到下一个定时时间到来的时候，把这个last的值-250后送入组建
        progressTimer.updateLastTime(time: position + 250)
        rtcManager.seek(time: position)
        cumulativeScore = view.scoringView.getCumulativeScore()
        ktvView.gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: lyricModel!.lines.count * 100)
    }
}

extension MainTestVC {
    struct Item {
        let code: Int
        let name: String
        let des: String
        /// 0：XML，1: LRC，2：webvtt 3.支持打分的xml 4.支持打分的lrc
        var lyricType: Int = 0
    }
}
