//
//  ViewTestVC.swift
//  Demo
//
//  Created by ZYP on 2022/12/21.
//

import UIKit
import AgoraLyricsScore

class ViewTestVC: UIViewController {

    let karaokeView = KaraokeView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addSubview(karaokeView)
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
//        karaokeView.spacing = 0
//        karaokeView.scoringEnabled = false
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
