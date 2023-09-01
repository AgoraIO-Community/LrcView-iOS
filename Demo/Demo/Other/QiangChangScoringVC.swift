//
//  QiangChangScoringVC.swift
//  Demo
//
//  Created by ZYP on 2023/9/1.
//

import UIKit

class QiangChangScoringVC: UIViewController {
    private let qiangChangScoringView = QiangChangScoringView()
    private var timer = GCDTimer()
    private var timeCount = 15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        commonInit()
    }
    
    private func setupUI() {
        sayHello()
        view.addSubview(qiangChangScoringView)
        qiangChangScoringView.frame = view.bounds
    }
    
    private func commonInit() {
        qiangChangScoringView.delegate = self
    }
    
    fileprivate func handleQiang() {
        timer.scheduledMillisecondsTimer(withName: "QiangChangScoringVC",
                                         countDown: 1000000,
                                         milliseconds: 100,
                                         queue: .main) { [weak self](_, _) in
            guard let self = self else { return }
            timeCount -= 1
            if timeCount > 0 {
                qiangChangScoringView.updateOkTime(num: timeCount)
                return
            }
            
            if timeCount <= 0 {
                timer.destoryAllTimer()
                timeCount = 15
                handleOk()
            }
        }
    }
    
    fileprivate func handleOk() {
        // 获取pitch信息
        
        // 调用对比算法
    }
}

extension QiangChangScoringVC: QiangChangScoringViewDelegate {
    func qiangChangScoringViewDidTap(action: QiangChangScoringView.Action) {
        switch action {
        case .qiang:
            handleQiang()
            break
        case .ok:
            handleOk()
            break
        }
    }
}
