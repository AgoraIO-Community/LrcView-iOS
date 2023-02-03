//
//  IncentiveView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/29.
//

import UIKit
import WebKit

public class IncentiveView: UIView {
    private let gifViews: [GifView] = [.init(), .init(), .init()]
    private var currentIndex = 0
    public let width: CGFloat = 384/2
    public let heigth: CGFloat = 90/2
    private var link: CADisplayLink?
    private var combo = 0
    private var lastName = ""
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        for gifView in gifViews {
            gifView.isHidden = true
            addSubview(gifView)
            gifView.translatesAutoresizingMaskIntoConstraints = false
            gifView.contentMode = .scaleAspectFit
            gifView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            gifView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            gifView.heightAnchor.constraint(equalToConstant: heigth).isActive = true
            gifView.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show(score: Int) {
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
        
        guard let path = Bundle.currentBundle.path(forResource: name, ofType: "gif") else {
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
        
        let index = findIndexOfLabel()
        bringSubviewToFront(gifViews[index])
        gifViews[index].startGif(filePath: path, combo: combo)
        gifViews[index].isHidden = false
        setupLinkIfNeed()
    }
    
    public func reset() {
        link?.invalidate()
        link = nil
        combo = 0
        lastName = ""
    }
    
    private func findIndexOfLabel() -> Int {
        var index = currentIndex + 1
        index = index < gifViews.count ? index : 0
        currentIndex = index
        return index
    }
    
    private func setupLinkIfNeed() {
        if link == nil {
            link = CADisplayLink(target: self, selector: #selector(timeOut))
            link?.preferredFramesPerSecond = 5
            link?.add(to: .current, forMode: .common)
        }
    }
    
    @objc func timeOut() {
        let current = Date().milliStamp
        for view in gifViews {
            if current - view.time > 2000 {
                view.isHidden = true
                view.stopGif()
            }
        }
    }
}

class GifView: UIView {
    private let imageView = UIImageView()
    private let comboLabel = IncentiveLabel()
    var time: Int64 = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        comboLabel.font = UIFont(name: "PingFangSC-Bold", size: 13)
        
        comboLabel.textAlignment = .center
        comboLabel.textColor = .white
        
        addSubview(imageView)
        addSubview(comboLabel)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        comboLabel.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        comboLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        comboLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 10).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startGif(filePath: String, combo: Int) {
        imageView.startGif(filePath: filePath)
        
        comboLabel.text = "×\(combo)"
        comboLabel.isHidden = combo == 0
        
        time = Date().milliStamp
    }
    
    func stopGif() {
        time = 0
        imageView.stopGif()
    }
}

extension UIImageView {
    func startGif(filePath: String) {
        guard let data = NSData(contentsOfFile: filePath) else { return }
        
        guard let imageSource = CGImageSourceCreateWithData(data, nil) else { return }
        let imageCount = CGImageSourceGetCount(imageSource)
        
        var images = [UIImage]()
        var totalDuration: TimeInterval = 0
        for i in 0..<imageCount {
            
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else {continue}
            let image = UIImage(cgImage: cgImage)
            images.append(image)
            
            guard let copyProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) else {
                continue
            }
            
            let properties = copyProperties as NSDictionary
            guard let gifDict = properties[kCGImagePropertyGIFDictionary]  as? NSDictionary else  {
                continue
            }
            guard let frameDuration = gifDict[kCGImagePropertyGIFDelayTime] as? NSNumber else {
                continue
            }
            totalDuration += frameDuration.doubleValue
        }
        
        animationImages = images
        animationDuration = totalDuration
        animationRepeatCount = 1
        
        startAnimating()
    }
    
    func stopGif() {
        stopAnimating()
        animationImages = []
        animationDuration = 0
        animationRepeatCount = 0
    }
}

class IncentiveLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let color = textColor
        let offset = shadowOffset
        
        let c = UIGraphicsGetCurrentContext()
        c?.setLineWidth(4.0)
        c?.setLineJoin(.round)
        c?.setTextDrawingMode(.strokeClip)
        textColor = UIColor.colorWithHex(hexStr: "#368CFF")
        super.drawText(in: rect)
        
        c?.setTextDrawingMode(.fill)
        textColor = color
        shadowOffset = .zero
        super.drawText(in: rect)
        
        shadowOffset = offset
    }
}
