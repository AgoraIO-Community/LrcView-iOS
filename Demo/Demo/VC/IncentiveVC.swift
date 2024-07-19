//
//  IncentiveVC.swift
//  Demo
//
//  Created by ZYP on 2023/1/29.
//

import UIKit

import ScoreEffectUI
import AgoraLyricsScore

class IncentiveVC: UIViewController {

    let incentiveView = IncentiveView()
    var start = true
    private var timer = GCDTimer()
    let list = [0, 80, 60, 83, 89, 90, 83, 84, 85]
    var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(incentiveView)
        incentiveView.frame = .init(x: 100, y: 100, width: 200, height: 200)
        timer.scheduledMillisecondsTimer(withName: "EmitterVC", countDown: 1000000, milliseconds: 1000, queue: .main) { [weak self](_, time) in
            guard let self = self else { return }
            
            if self.index > self.list.count-1 {
//                self.index = 0
            }
            else {
                let score = self.list[self.index]
                self.incentiveView.show(score: score)
            }
            self.index += 1
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}
