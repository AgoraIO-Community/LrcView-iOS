//
//  FirstToneHintView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2022/12/22.
//

import UIKit

class FirstToneHintView: UIView {
    private var style = FirstToneHintViewStyle()
    private let loadViews: [UIView] = [.init(), .init(), .init()]
    private var loadViewConstraints = [NSLayoutConstraint]()
    /// 剩余开始时间 ms
    private var remainingTime = 0
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
        guard time > -2000 else { /** 超过2s不再进行有效输入 **/
            return
        }
        Log.info(text: "remainingTime: \(time)", tag: logTag)
        
        if time < 0 {
            reset()
            return
        }
        
        remainingTime = time
        isHidden = false
        
        if remainingTime >= 3 * 1000 {
            loadViews[0].isHidden = !self.loadViews[0].isHidden
            loadViews[1].isHidden = false
            loadViews[2].isHidden = false
            return
        }
        
        if remainingTime >= 2 * 1000 {
            loadViews[0].isHidden = true
            loadViews[1].isHidden = true
            loadViews[2].isHidden = false
            return
        }
        
        if remainingTime >= 1 * 1000 {
            loadViews[0].isHidden = true
            loadViews[1].isHidden = true
            loadViews[2].isHidden = true
            return
        }
        
        if remainingTime < 1 * 1000, time < 115 {
            isHidden = true
            return
        }
    }
    
    func reset() {
        isHidden = true
        self.loadViews[0].isHidden = false
        self.loadViews[1].isHidden = false
        self.loadViews[2].isHidden = false
    }
    
}
