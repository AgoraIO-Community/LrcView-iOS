//
//  QiangChangVC.swift
//  Demo
//
//  Created by ZYP on 2023/4/17.
//

import UIKit
import AgoraRtcKit
import RTMTokenBuilder
import AgoraLyricsScore
import ScoreEffectUI

class QiangChangVC: UIViewController {
    typealias Item = MainTestVC.Item
    let karaokeView = KaraokeView(frame: .zero, loggers: [ConsoleLogger()])
    let lineScoreView = LineScoreView()
    let gradeView = GradeView()
    let incentiveView = IncentiveView()
    let skipButton = UIButton()
    let setButton = UIButton()
    let quickButton = UIButton()
    let changeButton = UIButton()
    let pauseButton = UIButton()
    var agoraKit: AgoraRtcEngineKit!
    var token: String!
    var mcc: AgoraMusicContentCenter!
    var mpk: AgoraMusicPlayerProtocol!
    
    var song: SongListVC.Song!
    
    var currentSongIndex = 0
    private var timer = GCDTimer()
    var cumulativeScore = 0
    var lyricModel: LyricModel!
    var pitchModel: PitchModel!
    var noLyric = false
    var isPause = false
    var preTime = 0
    var endTime = 0
    let songs: [SongListVC.Song] = [
        .init(name: "后来", singer: "刘若英", code: 0, startTime: 0, endTime: 341000, exten: "mp3"),
        .init(name: "十年", singer: "陈奕迅", code: 0, startTime: 0, endTime: 204000, exten: "mp3"),
        .init(name: "简单爱", singer: "周杰伦", code: 6625526603631810, startTime: 25639, endTime: 252783),
        .init(name: "1_108852_h0_(Vocals)", singer: "--", code: 0, startTime: 0, endTime: 32400, exten: "wav"),
        .init(name: "1_100949_h0_(Vocals)", singer: "--", code: 0, startTime: 0, endTime: 39000, exten: "wav"),
        .init(name: "1_119583_h0_(Vocals)", singer: "--", code: 0, startTime: 0, endTime: 29000, exten: "wav"),
        .init(name: "1_104085_h0_(Vocals)", singer: "--", code: 0, startTime: 0, endTime: 24000, exten: "wav"),
        .init(name: "1_119764_h0_(Vocals)", singer: "--", code: 0, startTime: 0, endTime: 28000, exten: "wav")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    deinit {
        print("=== deinit")
    }
    
    func setupUI() {
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
        karaokeView.scoringView.viewHeight = 100
        karaokeView.scoringView.topSpaces = 80
        karaokeView.scoringView.showDebugView = true
        karaokeView.lyricsView.draggable = false

        skipButton.setTitle("跳过前奏", for: .normal)
        setButton.setTitle("点歌", for: .normal)
        changeButton.setTitle("切歌", for: .normal)
        quickButton.setTitle("退出", for: .normal)
        pauseButton.setTitle("暂停", for: .normal)
        pauseButton.setTitle("继续", for: .selected)
        skipButton.backgroundColor = .red
        setButton.backgroundColor = .red
        changeButton.backgroundColor = .red
        quickButton.backgroundColor = .red
        pauseButton.backgroundColor = .red
        
        view.backgroundColor = .black
        view.addSubview(karaokeView)
        view.addSubview(gradeView)
        view.addSubview(incentiveView)
        view.addSubview(skipButton)
        view.addSubview(setButton)
        view.addSubview(changeButton)
        view.addSubview(quickButton)
        view.addSubview(pauseButton)
        view.addSubview(lineScoreView)
        
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        gradeView.translatesAutoresizingMaskIntoConstraints = false
        incentiveView.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        setButton.translatesAutoresizingMaskIntoConstraints = false
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        quickButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        lineScoreView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
        
        gradeView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: 15).isActive = true
        gradeView.leftAnchor.constraint(equalTo: karaokeView.leftAnchor, constant: 15).isActive = true
        gradeView.rightAnchor.constraint(equalTo: karaokeView.rightAnchor, constant: -15).isActive = true
        gradeView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        incentiveView.centerYAnchor.constraint(equalTo: karaokeView.scoringView.centerYAnchor).isActive = true
        incentiveView.centerXAnchor.constraint(equalTo: karaokeView.centerXAnchor, constant: -10).isActive = true
        
        lineScoreView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: karaokeView.scoringView.defaultPitchCursorX).isActive = true
        lineScoreView.topAnchor.constraint(equalTo: karaokeView.topAnchor, constant: karaokeView.scoringView.topSpaces).isActive = true
        lineScoreView.heightAnchor.constraint(equalToConstant: karaokeView.scoringView.viewHeight).isActive = true
        lineScoreView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        skipButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 100).isActive = true
        skipButton.topAnchor.constraint(equalTo: karaokeView.bottomAnchor, constant: 30).isActive = true
        
        setButton.leftAnchor.constraint(equalTo: skipButton.rightAnchor, constant: 45).isActive = true
        setButton.topAnchor.constraint(equalTo: karaokeView.bottomAnchor, constant: 30).isActive = true
        
        changeButton.leftAnchor.constraint(equalTo: skipButton.leftAnchor).isActive = true
        changeButton.topAnchor.constraint(equalTo: setButton.bottomAnchor, constant: 30).isActive = true
        
        quickButton.leftAnchor.constraint(equalTo: setButton.leftAnchor).isActive = true
        quickButton.topAnchor.constraint(equalTo: setButton.bottomAnchor, constant: 30).isActive = true
        
        pauseButton.leftAnchor.constraint(equalTo: skipButton.leftAnchor).isActive = true
        pauseButton.topAnchor.constraint(equalTo: changeButton.bottomAnchor, constant: 30).isActive = true
    }
    
    func commonInit() {
        skipButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        setButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        changeButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        quickButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        cumulativeScore = 0
        token = TokenBuilder.buildToken(Config.mccAppId,
                                        appCertificate: Config.mccCertificate,
                                        userUuid: "\(Config.mccUid)")
        initEngine()
        joinChannel()
        initMCC()
        karaokeView.delegate = self
    }
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }
    
    func joinChannel() { /** 目的：发布mic流、接收音频流 **/
        agoraKit.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        agoraKit.enableAudio()
        agoraKit.setClientRole(.broadcaster)
        let ret = agoraKit.joinChannel(byToken: nil,
                                       channelId: Config.channelId,
                                       uid: Config.hostUid,
                                       mediaOptions: option)
        print("joinChannel ret \(ret)")
    }
    
    var streamId: Int = 0
    func createDataStream() {
        let config = AgoraDataStreamConfig()
        config.syncWithAudio = false
        config.ordered = false
        let ret = agoraKit.createDataStream(&streamId, config: config)
        print("createDataStream ret \(ret)")
    }
    
    func initMCC() {
        let config = AgoraMusicContentCenterConfig()
        config.rtcEngine = agoraKit
        config.mccUid = Config.mccUid
        config.token = token
        config.appId = Config.mccAppId
        mcc = AgoraMusicContentCenter.sharedContentCenter(config: config)
        mcc.register(self)
        mpk = mcc.createMusicPlayer(delegate: self)
    }
    
    func mccPreload() {
//        let songcode = mcc.getInternalSongCode(songCode: song.code, jsonOption: "{\"format\":{\"highPart\":0}}")
//        song.code = songcode
        let ret = mcc.preload(songCode: song.code)
        if ret.isEmpty {
            print("preload error \(ret)")
            return
        }
        print("== preload success")
    }
    
    func mccGetSongSimpleInfo() {
        let ret = mcc.getSongSimpleInfo(songCode: song.code)
        if ret.isEmpty {
            print("GetSongSimpleInfo error \(ret)")
            return
        }
        print("== GetSongSimpleInfo success")
    }
    
    func mccOpen() {
        let ret = mpk.openMedia(songCode: song.code, startPos: 0)
        if ret != 0 {
            print("openMedia error \(ret)")
            return
        }
        print("== openMedia success")
    }
    
    var last = 0
    func mccPlay() {
        let ret = mpk.play()
        if ret != 0 {
            print("play error \(ret)")
            return
        }
        print("== play success")
        self.last = 0
        timer.scheduledMillisecondsTimer(withName: "QiangChangVC",
                                         countDown: 1000000,
                                         milliseconds: 20,
                                         queue: .main) { [weak self](_, time) in
            
            guard let self = self else { return }
            if self.isPause {
                return
            }
            
            var current = self.last
            current += 20
            
            if self.last == 0 {
                current = self.mpk.getPosition()
            }
            
            if time.truncatingRemainder(dividingBy: 1000) == 0 {
                current = self.mpk.getPosition()
            }
            
            
            self.last = current
            var time = current
            if time > 250 { /** 进度提前250ms, 第一个句子的第一个字得到更好匹配 **/
                time -= 250
            }
            if current + self.preTime < self.song.endTime + 20 {
                self.karaokeView.setProgress(progress: current + self.preTime)
            }
            else {
                self.isPause = true
                self.mpk.pause()
            }
        }
    }
    
    func mccGetLrc() {
        let requestId = mcc.getLyric(songCode: song.code, lyricType: song.isXML ? 0 : 1)
        print("== mccGetLrc requestId:\(requestId)")
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        switch sender {
        case skipButton:
            let toPosition = 25 * 1000
            mpk.seek(toPosition: toPosition)
            return
        case setButton:
            //            mcc.getMusicCollection(musicChartId: 1, page: 0, pageSize: 10, jsonOption: nil)
            
            
            let vc = SongListVC()
            vc.songs = songs
            vc.delegate = self
            self.present(vc, animated: true)
            return
        case changeButton:
            return
        case quickButton:
            agoraKit.disableAudio()
            timer.destoryAllTimer()
            mpk.stop()
            mcc.register(nil)
            agoraKit.destroyMediaPlayer(mpk)
            karaokeView.reset()
            gradeView.reset()
            incentiveView.reset()
            navigationController?.popViewController(animated: true)
            return
        case pauseButton:
            if !pauseButton.isSelected {
                karaokeView.scoringView.forceStopIndicatorAnimationWhenReachingContinuousZeros()
                isPause = true
                mpk.pause()
                pauseButton.isSelected = true
            }
            else {
                isPause = false
                mpk.resume()
                pauseButton.isSelected = false
            }
            return
        default:
            break
        }
    }
    
    func sendData(data: Data) {
        if streamId > 0 {
            agoraKit.sendStreamMessage(streamId, data: data)
        }
    }
    
    func createData(time: Int) -> Data {
        /// 把time包装json格式
        let dic = ["time": time]
        let data = try! JSONSerialization.data(withJSONObject: dic, options: [])
        return data
    }
    
    func createData(pitch: Double) -> Data {
        /// 把pitch包装json格式
        let dic = ["pitch": pitch]
        let data = try! JSONSerialization.data(withJSONObject: dic, options: [])
        return data
    }
    
    func updateView(param: Param) {
        karaokeView.backgroundImage = param.karaoke.backgroundImage
        karaokeView.scoringEnabled = param.karaoke.scoringEnabled
        karaokeView.spacing = param.karaoke.spacing
        karaokeView.setScoreLevel(level: param.karaoke.scoreLevel)
        karaokeView.setScoreCompensationOffset(offset: param.karaoke.scoreCompensationOffset)
        
        karaokeView.lyricsView.lyricLineSpacing = param.lyric.lyricLineSpacing
        karaokeView.lyricsView.noLyricTipsColor = param.lyric.noLyricTipsColor
        karaokeView.lyricsView.noLyricTipsText = param.lyric.noLyricTipsText
        karaokeView.lyricsView.noLyricTipsFont = param.lyric.noLyricTipsFont
        karaokeView.lyricsView.activeLineUpcomingFontSize = param.lyric.activeLineUpcomingFontSize
        karaokeView.lyricsView.inactiveLineTextColor = param.lyric.inactiveLineTextColor
        karaokeView.lyricsView.activeLineUpcomingTextColor = param.lyric.activeLineUpcomingTextColor
        karaokeView.lyricsView.activeLinePlayedTextColor = param.lyric.activeLinePlayedTextColor
        karaokeView.lyricsView.waitingViewHidden = param.lyric.waitingViewHidden
        karaokeView.lyricsView.inactiveLineFontSize = param.lyric.inactiveLineFontSize
        karaokeView.lyricsView.firstToneHintViewStyle.backgroundColor = param.lyric.firstToneHintViewStyle.backgroundColor
        karaokeView.lyricsView.firstToneHintViewStyle.size = param.lyric.firstToneHintViewStyle.size
        karaokeView.lyricsView.firstToneHintViewStyle.bottomMargin = param.lyric.firstToneHintViewStyle.bottomMargin
        karaokeView.lyricsView.maxWidth = param.lyric.maxWidth
        karaokeView.lyricsView.draggable = param.lyric.draggable
        
        karaokeView.scoringView.particleEffectHidden = param.scoring.particleEffectHidden
        karaokeView.scoringView.emitterImages = param.scoring.emitterImages
        karaokeView.scoringView.standardPitchStickViewHighlightColor = param.scoring.standardPitchStickViewHighlightColor
        karaokeView.scoringView.standardPitchStickViewColor = param.scoring.standardPitchStickViewColor
        karaokeView.scoringView.standardPitchStickViewHeight = param.scoring.standardPitchStickViewHeight
        karaokeView.scoringView.defaultPitchCursorX = param.scoring.defaultPitchCursorX
        karaokeView.scoringView.topSpaces = param.scoring.topSpaces
        karaokeView.scoringView.viewHeight = param.scoring.viewHeight
        karaokeView.scoringView.hitScoreThreshold = param.scoring.hitScoreThreshold
        karaokeView.scoringView.movingSpeedFactor = param.scoring.movingSpeedFactor
        karaokeView.scoringView.showDebugView = param.scoring.showDebugView
    }
}

extension QiangChangVC: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError \(errorCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("didJoinedOfUid \(uid)")
        createDataStream()
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("didJoinChannel withUid \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        if isPause {
            return
        }
        if let pitch = speakers.last?.voicePitch {
            karaokeView.setPitch(pitch: pitch)
        }
    }
}

extension QiangChangVC: AgoraMusicContentCenterEventDelegate {
    func onLyricResult(_ requestId: String, songCode: Int, lyricUrl: String?, errorCode: AgoraMusicContentCenterStatusCode) {
        print("=== onLyricResult requestId:\(requestId) lyricUrl:\(lyricUrl!)")
        
        if lyricUrl!.isEmpty { /** 网络偶问题导致的为空 **/
            DispatchQueue.main.async { [weak self] in
                self?.title = "无歌词地址"
            }
            return
        }
        else {
            DispatchQueue.main.async { [weak self] in
                self?.title = nil
            }
        }
        
        
    }
    
    func onSongSimpleInfoResult(_ requestId: String, songCode: Int, simpleInfo: String?, errorCode: AgoraMusicContentCenterStatusCode) {
        if let jsonData = simpleInfo?.data(using: .utf8) {
             do {
                 let jsonMsg = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
                 let format = jsonMsg["format"] as! [String: Any]
                 let highPart = format["highPart"] as! [[String: Any]]
                 let highStartTime = highPart[0]["highStartTime"] as! Int
                 let highEndTime = highPart[0]["highEndTime"] as! Int
                 self.preTime = highStartTime
                 self.song.startTime = highStartTime
                 self.song.endTime = highEndTime
                 print("== onSongSimpleInfoResult highStartTime:\(highStartTime)")
                 self.mccGetLrc()
             } catch {
                 print("Error while parsing JSON: \(error.localizedDescription)")
             }
         }
         if (errorCode == .errorGateway) {
             print("")
         }
    }
    
    func onPreLoadEvent(_ requestId: String, songCode: Int, percent: Int, lyricUrl: String?, status: AgoraMusicContentCenterPreloadStatus, errorCode: AgoraMusicContentCenterStatusCode) {
        print("== onPreLoadEvent \(status.rawValue) msg: \(errorCode)")
        if status == .OK { /** preload 成功 **/
            print("== preload ok")
            let isCustom = song.name == "简单爱"
            if isCustom {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    let songCode = song.code
                    let pitchPath = Bundle.main.path(forResource: "\(songCode)", ofType: "bin")!
                    let pitchData = try! Data(contentsOf: URL(fileURLWithPath: pitchPath))
                    let lyricPath = Bundle.main.path(forResource: "\(songCode)", ofType: "xml")!
                    let lyricData = try! Data(contentsOf: URL(fileURLWithPath: lyricPath))
                    pitchModel = KaraokeView.parsePitchData(data: pitchData)
                    let lyricModel = KaraokeView.parseLyricData(data: lyricData)
                    karaokeView.setPitchData(data: pitchModel)
                    karaokeView.setLyricData(data: lyricModel)
                    gradeView.setTitle(title: "spc \(song.name) - \(song.singer) [only pitch]")
                    mccOpen()
                }
                
                return
            }
        }
        
        if status == .error {
            print("onPreLoadEvent percent:\(percent) status:\(status.rawValue) msg:\(errorCode) lyricUrl:\(lyricUrl!)")
        }
    }
    
    func onMusicChartsResult(_ requestId: String, result: [AgoraMusicChartInfo], errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onMusicCollectionResult(_ requestId: String, result: AgoraMusicCollection, errorCode: AgoraMusicContentCenterStatusCode) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return}
            //            let songs = result.musicList.map({ SongListVC.Song(name: $0.name, singer: $0.singer, code: $0.songCode, climaxSegment: $0.climaxSegmentList) }).filter({ !$0.climaxSegment.isEmpty })
        }
    }
    
    
}


extension QiangChangVC: AgoraRtcMediaPlayerDelegate {
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        if state == .openCompleted {
            print("=== openCompleted")
            mccPlay()
        }
    }
    
    func AgoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo position: Int) {}
}

extension QiangChangVC: KaraokeDelegate {
    func onKaraokeView(view: KaraokeView, didDragTo position: Int) {
        /// drag正在进行的时候, 不会更新内部的progress, 这个时候设置一个last值，等到下一个定时时间到来的时候，把这个last的值-250后送入组建
        self.last = position + 250
        mpk.seek(toPosition: position)
        cumulativeScore = view.scoringView.getCumulativeScore()
        gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: lyricModel.lines.count * 100)
    }
    
    func onKaraokeView(view: KaraokeView,
                       didFinishLineWith model: LyricLineModel,
                       score: Int,
                       cumulativeScore: Int,
                       lineIndex: Int,
                       lineCount: Int) {
        lineScoreView.showScoreView(score: score)
        self.cumulativeScore = cumulativeScore
        gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: lineCount * 100)
        incentiveView.show(score: score)
    }
    
    func onKaraokeView(view: KaraokeView,
                       didFinishToneWith models: [PitchScoreModel],
                       cumulativeScore: Int) {
        self.cumulativeScore = cumulativeScore
        gradeView.setScore(cumulativeScore: cumulativeScore, totalScore: models.count * 100)
    }
}

extension QiangChangVC: ParamSetVCDelegate {
    func didSetParam(param: Param, noLyric: Bool) {
        self.noLyric = noLyric
        mpk.stop()
        timer.destoryTimer(withName: "QiangChangVC")
        self.last = 0
        karaokeView.reset()
        incentiveView.reset()
        gradeView.reset()
        updateView(param: param)
        mccPreload()
    }
}

extension QiangChangVC: SongListVCDelegate {
    func songListVCDidSelectedSong(song: SongListVC.Song) {
        self.song = song
        isPause = false
        pauseButton.isSelected = false
        mpk.stop()
        timer.destoryTimer(withName: "QiangChangVC")
        self.last = 0
        incentiveView.reset()
        gradeView.reset()
        karaokeView.reset()
        
        self.gradeView.isHidden = false
        self.karaokeView.scoringView.viewHeight = 100
        self.karaokeView.scoringView.topSpaces = 80
        self.karaokeView.scoringEnabled = true
        
        if song.code != 0 {
            mccPreload()
        }
        else {
            
            let pitchPath = Bundle.main.path(forResource: song.name, ofType: "pitch")!
            let pitchData = try! Data(contentsOf: URL(fileURLWithPath: pitchPath))
            pitchModel = KaraokeView.parsePitchData(data: pitchData)
            karaokeView.setPitchData(data: pitchModel)
            gradeView.setTitle(title: "spc \(song.name) - \(song.singer) [only pitch]")
            
            if let lyricPath = Bundle.main.path(forResource: song.name, ofType: "xml") {
                let lyricData = try! Data(contentsOf: URL(fileURLWithPath: lyricPath))
                let lyricModel = KaraokeView.parseLyricData(data: lyricData)
                karaokeView.setLyricData(data: lyricModel)
            }
            
            let musicPath = Bundle.main.path(forResource: song.name, ofType: song.exten)!
            let ret = mpk.open(musicPath, startPos: 0)
            if ret != 0 {
                print("=== error: \(ret)")
            }
        }
        
        print("songListVCDidSelectedSong \(song.code) \(preTime)")
    }
}

func trans(model: LyricModel, start: Int, end: Int) -> LyricModel? {
    var lines = [LyricLineModel]()
    
    var flag = false
    for line in model.lines {
        if line.beginTime == start {
            flag = true
        }
        if line.beginTime + line.duration == end {
            lines.append(line)
            break
        }
        if flag {
            lines.append(line)
        }
    }
    
    model.lines = lines
    model.preludeEndPosition = 0
    model.duration = lines.last!.beginTime + lines.last!.duration
    return model
}
