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
    let resetButton = UIButton()
    let goodButton = UIButton()
    let noneButton = UIButton()
    let fairButton = UIButton()
    let excellentButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        view.addSubview(incentiveView)
        incentiveView.frame = .init(x: 100, y: 100, width: 200, height: 200)
        view.addSubview(resetButton)
        view.addSubview(goodButton)
        view.addSubview(fairButton)
        view.addSubview(noneButton)
        view.addSubview(excellentButton)
        
        noneButton.frame = .init(x: 15, y: 350, width: 45, height: 45)
        goodButton.frame = .init(x: 15 + 60, y: 350, width: 45, height: 45)
        fairButton.frame = .init(x: 15 + 60 + 60, y: 350, width: 45, height: 45)
        excellentButton.frame = .init(x: 15 + 60 + 60 + 60, y: 350, width: 45, height: 45)
        resetButton.frame = .init(x: 15 , y: 420, width: 45, height: 45)
        
        noneButton.backgroundColor = .blue
        goodButton.backgroundColor = .blue
        fairButton.backgroundColor = .blue
        excellentButton.backgroundColor = .blue
        resetButton.backgroundColor = .blue
        
        noneButton.setTitle("none", for: .normal)
        goodButton.setTitle("good", for: .normal)
        fairButton.setTitle("fair", for: .normal)
        excellentButton.setTitle("excellent", for: .normal)
        resetButton.setTitle("reset", for: .normal)
        
        noneButton.setTitleColor(.white, for: .normal)
        goodButton.setTitleColor(.white, for: .normal)
        fairButton.setTitleColor(.white, for: .normal)
        excellentButton.setTitleColor(.white, for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
    }
    
    func commonInit() {
        noneButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        goodButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        fairButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        excellentButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        if sender == resetButton {
            incentiveView.reset()
            return
        }
        
        if sender == goodButton {
            incentiveView.show(score: 86)
            return
        }
        
        if sender == noneButton {
            incentiveView.show(score: 0)
            return
        }
        
        if sender == fairButton {
            incentiveView.show(score: 70)
            return
        }
    }
}
