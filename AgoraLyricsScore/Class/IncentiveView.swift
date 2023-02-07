//
//  IncentiveView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/29.
//

import UIKit

/// 激励视图
public class IncentiveView: UIView {
    private var itemViews: [IncentiveItemView]!
    private var combo = 0
    private var lastName = ""
    private let logTag = "IncentiveView"
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        itemViews = [.init(), .init(), .init(), .init(), .init()]
        for view in itemViews {
            view.isHidden = true
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.contentMode = .scaleAspectFit
            view.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            view.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    @objc public func show(score: Int) {
        var tempName: String?
        
        if score >= 60, score < 75 {
            tempName = "fair"
        }
        else if score >= 75, score < 90 {
            tempName = "good"
        }
        else if score >= 90, score <= 100 {
            tempName = "excellent"
        }
        else {
            combo = 0
        }
        
        guard let name = tempName else { return }
        guard let image =  Bundle.currentBundle.image(name: name) else {
            return
        }
        
        if lastName == name {
            if combo == 0 {
                combo += 2
            }
            else {
                combo += 1
            }
        }
        else {
            lastName = name
            combo = 0
        }
        
        guard let view = getView() else {
            Log.error(error: "getView == nil", tag: logTag)
            return
        }
        bringSubviewToFront(view)
        view.showAnimation(image: image, combo: combo)
    }
    
    public func reset() {
        combo = 0
        lastName = ""
    }
    
    private func getView() -> IncentiveItemView? {
        return itemViews.first(where: { $0.canUse })
    }
}

class IncentiveItemView: UIView, CAAnimationDelegate {
    private let imageView = UIImageView()
    private let comboLabel = IncentiveLabel()
    fileprivate var canUse = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        comboLabel.font = UIFont(name: "PingFangSC-Bold", size: 13)
        
        comboLabel.textAlignment = .center
        comboLabel.textColor = .white
        
        addSubview(imageView)
        addSubview(comboLabel)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        comboLabel.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        comboLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        comboLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -5).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func showAnimation(image: UIImage, combo: Int) {
        canUse = false
        comboLabel.text = "×\(combo)"
        comboLabel.isHidden = combo == 0
        imageView.image = image
        isHidden = false
        
        let transformAnimation = CABasicAnimation(keyPath: "transform.scale")
        transformAnimation.fromValue = 1.6
        transformAnimation.toValue = 1
        transformAnimation.duration = 0.3
        
        let opacityAnimation1 = CABasicAnimation(keyPath: "opacity")
        opacityAnimation1.fromValue = 0
        opacityAnimation1.toValue = 1
        opacityAnimation1.duration = 0.3
        
        let opacityAnimation2 = CABasicAnimation(keyPath: "opacity")
        opacityAnimation2.beginTime = 0.3 + 1.4
        opacityAnimation2.fromValue = 1
        opacityAnimation2.toValue = 0
        opacityAnimation2.duration = 0.3
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [transformAnimation, opacityAnimation1, opacityAnimation2]
        animationGroup.duration = 2
        animationGroup.isRemovedOnCompletion = false
        animationGroup.fillMode = .forwards
        animationGroup.delegate = self
        
        layer.add(animationGroup, forKey: "animationGroup")
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            isHidden = true
            layer.removeAnimation(forKey: "animationGroup")
            canUse = true
        }
    }
}

class IncentiveLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let color = textColor
        let offset = shadowOffset
        
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(4.0)
        context?.setLineJoin(.round)
        context?.setTextDrawingMode(.strokeClip)
        textColor = UIColor.colorWithHex(hexStr: "#368CFF")
        super.drawText(in: rect)
        
        context?.setTextDrawingMode(.fill)
        textColor = color
        shadowOffset = .zero
        super.drawText(in: rect)
        
        shadowOffset = offset
    }
}
