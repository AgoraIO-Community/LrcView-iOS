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
        
        label.text = "一二三四五六七八九十甲乙丙丁appleABCDEFGHIJKLMNOPQRSTUVWXYZ"
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 120).isActive = true
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        label.status = .normal
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// 根据“一二三四五六七八九十甲乙丙丁ABCDEFGHIJKLMNOPQRSTUVWXYZ”内容创建一个 WorkItem 数组，其中 startTime 和 endTime 都为 当前文字下标 * 10。
//        count += 1
//        let words = label.text?.map { String($0) } ?? []
//        let totalCount = words.count * 2 // 每个字需要2次点击完成着色
//        let currentProgress = min(Double(count) * 0.5, Double(words.count)) // 每次增加0.5个字的进度
//        
//        let wordItems = words.enumerated().map {
//            let item = LyricLabelLineWrap.WordItem(text: $0.element, 
//                                                 startTime: Double($0.offset) * 10.0, 
//                                                  endTime: Double($0.offset + 1) * 10.0)
//            // 计算当前字的进度：当前总进度 - 字的位置，限制在0~1之间
//            item.progressRate = max(0, min(currentProgress - Double($0.offset), 1.0))
//            return item
//        }
//        label.update(wordItems: wordItems)
//        
//        // 重置计数器当达到最大值时
//        if count >= totalCount {
//            count = 0
//        }
    }
    

}
