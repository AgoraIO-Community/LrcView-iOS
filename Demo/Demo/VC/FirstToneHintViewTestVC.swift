//
//  ExpTestVC.swift
//  Demo
//
//  Created by ZYP on 2022/12/22.
//

import UIKit
import AgoraLyricsScore

/// 测试等待视图
class FirstToneHintViewTestVC: UIViewController {

    let karaokeView = KaraokeView()
    private var timer = GCDTimer()
    var progress: UInt = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "745012", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        let model = KaraokeView.parseLyricData(lyricFileData: data)!
        model.preludeEndPosition = 6 * 1000
        karaokeView.setLyricData(data: model, usingInternalScoring: true)
    }
    
    func setupUI() {
        view.backgroundColor = .white
        view.addSubview(karaokeView)
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    func commonInit() {}
    
    deinit {
        timer.destoryTimer(withName: "ExpTestVC")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        timer.scheduledMillisecondsTimer(withName: "ExpTestVC", countDown: 1000000, milliseconds: 10, queue: .main) { [weak self](_, time) in
            guard let self = self else { return }
            self.progress += 10
            self.karaokeView.setProgress(progress: self.progress)
        }
    }
}
