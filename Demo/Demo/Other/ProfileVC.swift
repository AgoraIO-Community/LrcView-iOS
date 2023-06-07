//
//  ProfileVC.swift
//  Demo
//
//  Created by ZYP on 2023/2/27.
//

import Foundation
import AgoraLyricsScore

class ProfileVC: UIViewController {
    let karaokeView = KaraokeView()
    var progress = 0
    private var timer = GCDTimer()
    var model: LyricModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
        karaokeView.scoringView.viewHeight = 100
        karaokeView.scoringView.topMargin = 80
        karaokeView.lyricsView.showDebugView = false
        view.addSubview(karaokeView)
        
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "745012", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        model = KaraokeView.parseLyricData(data: data)!
        karaokeView.setLyricData(data: model)
        var count = 0
        timer.scheduledMillisecondsTimer(withName: "ProfileVC", countDown: 1000000, milliseconds: 20, queue: .main) { [weak self](_, time) in
            guard let self = self else { return }
            self.progress += 20
            
            if self.progress > self.model.duration {
                self.progress = 0
                self.timer.destoryAllTimer()
            }
            
            self.karaokeView.setProgress(progress: self.progress)
            
            count += 1
            if count == 3 {
                count = 0
                self.karaokeView.setPitch(pitch: Double.random(in: 87...300))
            }
            
        }
    }
    
}
