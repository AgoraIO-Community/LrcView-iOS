//
//  IncentiveVC.swift
//  Demo
//
//  Created by ZYP on 2023/1/29.
//

import UIKit


import AgoraLyricsScore

class IncentiveVC: UIViewController {

    let incentiveView = IncentiveView()
    var start = true
    private var timer = GCDTimer()
    let list = [0, 65, 65, 70, 90, 0, 55, 1, 90]
    var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(incentiveView)
        incentiveView.frame = .init(x: 100, y: 100, width: 200, height: 200)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        timer.scheduledMillisecondsTimer(withName: "EmitterVC", countDown: 1000000, milliseconds: 1000, queue: .main) { [weak self](_, time) in
            guard let self = self else { return }
            self.index += 1
            if self.index > self.list.count-1 {
                self.index = 0
            }
            let score = self.list[self.index]
            self.incentiveView.show(score: score)
        }
    }
}
