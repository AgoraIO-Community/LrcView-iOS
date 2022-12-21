//
//  ParserTestVC.swift
//  Demo
//
//  Created by ZYP on 2022/12/21.
//

import UIKit
import AgoraLyricsScore

class ParserTestVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "745012", ofType: "xml")!)
//        let data = try! Data(contentsOf: url)
//        let model = KaraokeView.parseLyricData(data: data)
//        let des = model?.description
//        print(des)
        
        
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "lrc", ofType: "lrc")!)
        let data = try! Data(contentsOf: url)
        let model = KaraokeView.parseLyricData(data: data)
        let des = model?.description
        print(des)
    }
    

    

}
