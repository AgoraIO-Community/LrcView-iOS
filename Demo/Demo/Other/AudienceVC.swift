//
//  AudienceVC.swift
//  Demo
//
//  Created by ZYP on 2023/3/21.
//

import AgoraRtcKit
import AgoraLyricsScore
import ScoreEffectUI
import RTMTokenBuilder

/// 观众端
class AudienceVC: UIViewController {
    var agoraKit: AgoraRtcEngineKit!
    let ktvView = KTVView()
    var mcc: AgoraMusicContentCenter!
    private var timer = GCDTimer()
    var token: String!
    var lyricUrl: String?
    var lyricModel: LyricModel!
    var last = 0
    var position: Int?
    
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
        token = TokenBuilder.buildToken(Config.mccAppId,
                                        appCertificate: Config.mccCertificate,
                                        userUuid: "\(Config.mccUid)")
        initEngine()
        joinChannel()
    }
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = Config.rtcAppId
        config.audioScenario = .chorus
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }
    
    func joinChannel() {
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .audience
        option.publishMicrophoneTrack = false
        agoraKit.setClientRole(.audience)
        let ret = agoraKit.joinChannel(byToken: nil,
                                       channelId: Config.channelId,
                                       uid: Config.audioUid,
                                       mediaOptions: option)
        print("joinChannel ret \(ret)")
    }
    
    func fetch() {
        FileCache.fect(urlString: lyricUrl!, reqType: 0) { progress in

        } completion: { (filePath, _) in
            let url = URL(fileURLWithPath: filePath)
            let data = try! Data(contentsOf: url)
            let model = KaraokeView.parseLyricData(data: data)!
            self.lyricModel = model
            self.ktvView.karaokeView.setLyricData(data: model)
            self.ktvView.gradeView.setTitle(title: "\(model.name) - \(model.singer)")
        } fail: { error in
            print("fect fail")
        }
    }
    
    func startTimer() {
        self.last = 0
        timer.scheduledMillisecondsTimer(withName: "MainTestVC",
                                         countDown: 1000000,
                                         milliseconds: 20,
                                         queue: .main) { [weak self](_, time) in

            guard let self = self else { return }
            
            var current = self.last
            if time.truncatingRemainder(dividingBy: 1000) == 0, let pos = self.position {
                current = pos
            }
            current += 20

            self.last = current
            var time = current
            if time > 250 { /** 进度提前250ms, 第一个句子的第一个字得到更好匹配 **/
                time -= 250
            }
            self.ktvView.karaokeView.setProgress(progress: current )
        }
    }
}

extension AudienceVC: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("didOccurError \(errorCode)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("didJoinedOfUid \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("didJoinChannel withUid \(uid)")
    }
    
//    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
//        for speaker in speakers {
//            if speaker.uid == Config.hostUid {
//                let voicePitch = speaker.voicePitch
//                if voicePitch > 0 {
//                    print("voicePitch \(voicePitch)")
//                }
//
//            }
//        }
//    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   receiveStreamMessageFromUid uid: UInt,
                   streamId: Int,
                   data: Data) {
        if streamId == Config.hostUid {
            guard let str = String(data: data, encoding: .utf8) else {
                return
            }
            
            /// json str 转字典
            guard let dict = jsonStringToDict(str: str) else {
                return
            }
            
            if lyricUrl == nil {
                lyricUrl = dict["url"] as? String
                if lyricUrl != nil {
                    fetch()
                }
            }
            
            if self.lyricModel != nil { /** fetch完成后 **/
                if let time = dict["time"] as? Int {
                    if position == nil { /** 第一次设置 **/
                        position = time
                        startTimer()
                    }
                    position = time
                }
                
                if dict["type"] as! Int == 1 {
                    if let pitch = dict["pitch"] as? Double {
                        ktvView.karaokeView.setPitch(pitch: pitch)
                    }
                }
            }
            
            
        }
    }
    
    func jsonStringToDict(str: String) -> [String : Any]? {
        if let data = str.data(using: .utf8) {
            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                return dict as? [String : Any]
            } catch {
                print(error)
            }
        }
        return nil
    }
}

