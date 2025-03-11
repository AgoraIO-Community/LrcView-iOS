//
//  LyricLabelVC.swift
//  Demo
//
//  Created by ZYP on 2023/1/31.
//

import UIKit
import AgoraLyricsScore

class LyricLabelVC: UIViewController {
    let label = LyricLabelLineWrap()
    var count = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        
        label.text = "一二三四五六七八九十甲乙丙丁ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 120).isActive = true
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        label.status = .normal
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        
//        if label.progressRate < 1 {
//            label.status = .selectedOrHighlighted
//            label.progressRate += 0.05
//            title = "\(label.progressRate)"
//        }
//        else {
////            label.text = ""
////            label.status = .normal
////            label.progressRate = 0
////
////            label.text = "我们得失的安徽的"
////            label.status = .selectedOrHighlighted
//        }
//
//        count += 1
    }
    

}
