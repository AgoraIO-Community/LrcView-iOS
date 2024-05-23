//
//  CheckLyricVC.swift
//  Demo
//
//  Created by ZYP on 2024/5/21.
//

import UIKit
import AgoraLyricsScoreEx

class CheckLyricVC: UIViewController {
    let lyricsFileCheckView = LyricsFileCheckView(frame: .zero)
    let logTag = "CheckLyricVC"
    var model: LyricModelEx!
    let krcFileData: Data
    let pitchFileData: Data
    let songId: Int
    
    init(krcFileData: Data, pitchFileData: Data, songId: Int) {
        self.krcFileData = krcFileData
        self.pitchFileData = pitchFileData
        self.songId = songId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        commonInit()
        loadLyrics()
    }
    
    private func setup() {
        view.backgroundColor = .white
        view.addSubview(lyricsFileCheckView)
        lyricsFileCheckView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lyricsFileCheckView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            lyricsFileCheckView.leftAnchor.constraint(equalTo: view.leftAnchor),
            lyricsFileCheckView.rightAnchor.constraint(equalTo: view.rightAnchor),
            lyricsFileCheckView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func commonInit() {
        lyricsFileCheckView.delegate = self
    }
    
    private func loadLyrics() {
        
        guard let model = KaraokeViewEx.parseLyricData(krcFileData: krcFileData, pitchFileData: pitchFileData) else {
            fatalError("can not get a model")
        }
        
        let pitchDrawInfos = convertPitchDrawInfos(pitchFileData: pitchFileData)
        let lyricDrawInfos = convertLyricDrawInfos(model: model)
        
        lyricsFileCheckView.setDrawInfo(pitchDrawInfos: pitchDrawInfos, lyricLineDrawInfos: lyricDrawInfos)
        title = "[\(songId)]\(model.name)"
        self.model = model
    }
    /// 缩放因子
    var factor: CGFloat = 0.5
    private func convertPitchDrawInfos(pitchFileData: Data) -> [LyricsFileCheckView.PitchDrawInfo] {
        
        let model = parsePitch(fileContent: pitchFileData)
        guard let pitchModel = model else {
            fatalError("parsePitch error")
        }
        
        let pitchInfos = pitchModel.pitchDatas
        var pitchDrawInfos = [LyricsFileCheckView.PitchDrawInfo]()
        for pitchInfo in pitchInfos {
            
            let x = lyricsFileCheckView.defaultPitchCursorX + CGFloat(pitchInfo.startTime) * factor
            let width = CGFloat(pitchInfo.duration) * factor
            
            let rect = CGRect(x: x, y: 15, width: width, height: 45)
            let pitchDrawInfo = LyricsFileCheckView.PitchDrawInfo(rect: rect, pitchInfo: pitchInfo)
            pitchDrawInfos.append(pitchDrawInfo)
        }
        
        return pitchDrawInfos
    }
    
    private func convertLyricDrawInfos(model: LyricModelEx) -> [LyricsFileCheckView.LyricLineDrawInfo] {
        var lyricLineDrawInfos = [LyricsFileCheckView.LyricLineDrawInfo]()
        for line in model.lines {
            let x = lyricsFileCheckView.defaultPitchCursorX +  CGFloat(line.beginTime) * factor
            let width = CGFloat(line.duration) * factor
            let lineRect = CGRect(x: x, y: 15 + 45 + 10, width: width, height: 45)
            
            var toneDrawInfos = [LyricsFileCheckView.LyricToneDrawInfo]()
            for tone in line.tones {
                let x = lyricsFileCheckView.defaultPitchCursorX + CGFloat(tone.beginTime) * factor
                let width = CGFloat(tone.duration) * factor
                let rect = CGRect(x: x, y: lineRect.maxY + 10, width: width, height: 45)
                let lyricDrawInfo = LyricsFileCheckView.LyricToneDrawInfo(rect: rect, toneInfo: tone)
                toneDrawInfos.append(lyricDrawInfo)
            }
            
            let lyricLineDrawInfo = LyricsFileCheckView.LyricLineDrawInfo(rect: lineRect,
                                                                          toneDrawInfos: toneDrawInfos, lineInfo: line)
            lyricLineDrawInfos.append(lyricLineDrawInfo)
        }
        return lyricLineDrawInfos
    }

}

extension CheckLyricVC: LyricsFileCheckViewDelegate {
    func lyricsFileCheckView(_ view: LyricsFileCheckView, didSelectRowAt index: Int) {
        let beginTime = model.lines[index].beginTime
        let x = CGFloat(beginTime) * factor
        let point = CGPoint(x: x, y: 0)
        view.seek(point: point)
    }
    
    func lyricsFileCheckView(_ view: LyricsFileCheckView, didScrollAt point: CGPoint) {
        let progress = UInt(max(point.x, 0) / factor)
        view.showProgress(progress: progress)
    }
}

extension CheckLyricVC {
    func parsePitch(fileContent data: Data) -> PitchModel? {
        /// 把data转成PitchParser
        guard !data.isEmpty else {
            return nil
        }
        
        do {
            let pitchModel = try JSONDecoder().decode(PitchModel.self, from: data)
            return pitchModel
        } catch let error {
            Log.error(error: error.localizedDescription, tag: logTag)
            return nil
        }
    }
    
    struct PitchInfo: Codable {
        let pitch: Double
        let startTime: UInt
        let duration: UInt
    }
    
    struct PitchModel: Codable {
        let pitchDatas: [PitchInfo]
    }
}
