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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(incentiveView)
        incentiveView.frame = .init(x: 0, y: 150, width: incentiveView.width, height: incentiveView.heigth)
        timer.scheduledMillisecondsTimer(withName: "EmitterVC", countDown: 1000000, milliseconds: 1000, queue: .main) { [weak self](_, time) in
            guard let self = self else { return }
            /// Int.random(in: 40...100)
            self.incentiveView.show(score: 80)
        }
    }
    

}
