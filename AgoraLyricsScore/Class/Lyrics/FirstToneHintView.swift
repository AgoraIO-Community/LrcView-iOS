//
//  FirstToneHintView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/22.
//

import UIKit

class FirstToneHintView: UIView {
    var style = FirstToneHintViewStyle() { didSet { updateUI() } }
    private let loadViews: [UIView] = [.init(), .init(), .init()]
    private var loadViewConstraints = [NSLayoutConstraint]()
    /// 剩余开始时间 ms
    private var remainingTime = 0
    private var lastRemainingTime = 0
    fileprivate let logTag = "FirstToneHintView"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        for view in loadViews {
            view.backgroundColor = style.backgroundColor
            view.layer.cornerRadius = style.size / 2
            view.layer.masksToBounds = true
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            let widthConstraint = view.widthAnchor.constraint(equalToConstant: style.size)
            let heightConstraint = view.heightAnchor.constraint(equalToConstant: style.size)
            widthConstraint.isActive = true
            heightConstraint.isActive = true
            loadViewConstraints.append(widthConstraint)
            loadViewConstraints.append(heightConstraint)
        }
        
        loadViews[1].centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadViews[1].centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        loadViews[0].leftAnchor.constraint(equalTo: loadViews[1].rightAnchor, constant: 10).isActive = true
        loadViews[0].centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        loadViews[2].rightAnchor.constraint(equalTo: loadViews[1].leftAnchor, constant: -10).isActive = true
        loadViews[2].centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        isHidden = true
    }
    
    private func updateUI() {
        for view in loadViews {
            view.backgroundColor = style.backgroundColor
            view.layer.cornerRadius = style.size / 2
        }
        
        for constraint in loadViewConstraints {
            constraint.constant = style.size
        }
    }
    
    func updateStyle(style: FirstToneHintViewStyle) {
        self.style = style
        updateUI()
    }
    
    /// 设置剩余开始时间 （前奏时间 - 当前歌曲进度）
    /// - Parameter time: 剩余开始唱第一句的时间
    func setRemainingTime(time: Int) {
        if time < 0 {
            reset()
            return
        }
        
        /** 过滤，500ms设置一次 **/
        if lastRemainingTime == 0 {
            lastRemainingTime = time
        }
        if lastRemainingTime - time < 500 {
            return
        }
        lastRemainingTime = time
        
        remainingTime = time
        Log.info(text: "remainingTime: \(remainingTime)", tag: logTag)
        isHidden = remainingTime < 1 * 1000 && time < 115
        loadViews[0].isHidden = (remainingTime >= 3 * 1000) ? !loadViews[0].isHidden : true
        loadViews[1].isHidden = !(remainingTime >= 2 * 1000)
        loadViews[2].isHidden = !(remainingTime >= 1 * 1000)
    }
    
    func reset() {
        isHidden = true
        self.loadViews[0].isHidden = false
        self.loadViews[1].isHidden = false
        self.loadViews[2].isHidden = false
        lastRemainingTime = 0
        remainingTime = 0
    }
    
}
