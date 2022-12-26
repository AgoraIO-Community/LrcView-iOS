//
//  NoLyricsTestVC.swift
//  Demo
//
//  Created by ZYP on 2022/12/23.
//

import UIKit
import AgoraLyricsScore

class NoLyricsTestVC: UIViewController {
    let karaokeView = KaraokeView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        karaokeView.lyricsView.noLyricTipsFont = .systemFont(ofSize: 20)
        karaokeView.lyricsView.noLyricTipsText = "哈哈asdasd"
        karaokeView.lyricsView.noLyricTipsColor = .red
        karaokeView.setLyricData(data: .empty)
    }
    
    func setupUI() {
        view.backgroundColor = .black
        view.addSubview(karaokeView)
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.heightAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    func commonInit() {}
    
    

}
