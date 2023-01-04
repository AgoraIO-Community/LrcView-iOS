//
//  LocalPitchView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/4.
//

import UIKit

class LocalPitchView: UIView {
    private let bgView = UIImageView()
    private let verticalLineView = UIImageView()
    private let indicatedView = UIImageView()
    private var indicatedViewCenterYAnchor: NSLayoutConstraint!
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        bgView.image = Bundle.currentBundle.image(name: "bg_scoring_left")
        verticalLineView.image = Bundle.currentBundle.image(name: "icon_vertical_line")
        indicatedView.image = Bundle.currentBundle.image(name: "icon_trangle")
        backgroundColor = .clear
        addSubview(bgView)
        addSubview(verticalLineView)
        addSubview(indicatedView)
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        verticalLineView.translatesAutoresizingMaskIntoConstraints = false
        indicatedView.translatesAutoresizingMaskIntoConstraints = false
        
        bgView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        bgView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        bgView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        bgView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        verticalLineView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        verticalLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        verticalLineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        indicatedView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        indicatedViewCenterYAnchor = indicatedView.centerYAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        indicatedViewCenterYAnchor.isActive = true
    }
    
    /// 设置游标位置
    /// - Parameter y: 从top到bottom方向上的距离
    func setIndicatedViewY(y: CGFloat) {
        let constant = (bounds.height - y) * -1
        indicatedViewCenterYAnchor.constant = constant
    }
}
