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
        view.backgroundColor = .black
        view.addSubview(incentiveView)
        incentiveView.frame = .init(x: 100, y: 100, width: 200, height: 200)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        timer.scheduledMillisecondsTimer(withName: "EmitterVC", countDown: 1000000, milliseconds: 500, queue: .main) { [weak self](_, time) in
//            guard let self = self else { return }
//            /// Int.random(in: 40...100)
//            self.incentiveView.show(score: Int.random(in: 40...100))
//        }
        incentiveView.show(score: Int.random(in: 40...100))
    }
}
