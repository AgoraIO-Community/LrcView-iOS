//
//  LocalPitchView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/4.
//

import UIKit

class LocalPitchView: UIView {
    private let emitter = Emitter()
    private let bgView = UIImageView()
    private let verticalLineView = UIImageView()
    private let indicatedView = UIImageView()
    private var labels: [UILabel] = [.init(), .init(), .init(), .init(), .init()]
    private var labelCenterYConstraints = [NSLayoutConstraint]()
    private var currentLabelIndex = 0
    private var indicatedCenterYConstant: CGFloat = 0.0
    static let scoreAnimateWidth: CGFloat = 30
    /// 游标的起始位置
    var defaultPitchCursorX: CGFloat = 100
    var emitterImages = [UIImage]() {
        didSet {
            emitter.images = emitterImages
        }
    }
    private var indicatedViewCenterYAnchor: NSLayoutConstraint!
    fileprivate let logTag = "LocalPitchView"
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
        for label in labels {
            label.font = .systemFont(ofSize: 11)
            label.textColor = .white
            addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
        }
        layer.addSublayer(emitter.layer)
        
        bgView.translatesAutoresizingMaskIntoConstraints = false
        verticalLineView.translatesAutoresizingMaskIntoConstraints = false
        indicatedView.translatesAutoresizingMaskIntoConstraints = false
        
        bgView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        bgView.rightAnchor.constraint(equalTo: rightAnchor, constant: -1 * LocalPitchView.scoreAnimateWidth).isActive = true
        bgView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        bgView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        verticalLineView.rightAnchor.constraint(equalTo: rightAnchor, constant: -1 * (LocalPitchView.scoreAnimateWidth - 0.5)).isActive = true
        verticalLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        verticalLineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        for label in labels {
            label.leftAnchor.constraint(equalTo: verticalLineView.rightAnchor, constant: 5).isActive = true
            let labelCenterYConstraint = label.centerYAnchor.constraint(equalTo: bottomAnchor)
            labelCenterYConstraint.isActive = true
            labelCenterYConstraints.append(labelCenterYConstraint)
        }
        
        indicatedView.rightAnchor.constraint(equalTo: rightAnchor, constant: -1 * LocalPitchView.scoreAnimateWidth).isActive = true
        indicatedViewCenterYAnchor = indicatedView.centerYAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        indicatedViewCenterYAnchor.isActive = true
    }
    
    /// 设置游标位置
    /// - Parameter y: 从top到bottom方向上的距离
    func setIndicatedViewY(y: CGFloat) {
        let constant = (bounds.height - y) * -1
        let duration: TimeInterval = indicatedCenterYConstant < constant ? 0.05 : 0.15
        indicatedCenterYConstant = constant
        indicatedViewCenterYAnchor.constant = constant
        UIView.animate(withDuration: duration, delay: 0, options: []) { [weak self] in
            self?.layoutIfNeeded()
        }
        emitter.setupEmitterPoint(point: .init(x: defaultPitchCursorX, y: y))
    }
      
    /// 开启粒子动画
    func startEmitter() {
        emitter.start()
    }
    
    /// 暂停粒子动画
    func stopEmitter() {
        emitter.stop()
    }
    
    func showScoreView(score: Int) {
        let viewHeight = bounds.height
        let index = findIndexOfLabel()
        let label = labels[index]
        label.text = "+\(score)"
        let constraint = labelCenterYConstraints[index]
        let startConstant: CGFloat = .random(in: 10...90) * -1
        let endConstant: CGFloat = (viewHeight - 10) * -1
        constraint.constant = startConstant
        label.alpha = 1
        label.isHidden = false
        layoutIfNeeded()
        constraint.constant = endConstant
        UIView.animate(withDuration: 0.4, delay: 0.2, options: []) {
            label.alpha = 0
            self.layoutIfNeeded()
        } completion: { completed in
            
        }
    }
    
    private func findIndexOfLabel() -> Int {
        var index = currentLabelIndex + 1
        index = index < labels.count ? index : 0
        currentLabelIndex = index
        return index
    }
}

class Emitter {
    let layer = CAEmitterLayer()
    var images = [UIImage]() {
        didSet {
            updateImageCells()
        }
    }
    
    var defaultImages: [UIImage] {
        var list = [UIImage]()
        let bundle = Bundle.currentBundle
        for i in 1..<9 {
            let image = bundle.image(name: "star\(i)")!
            list.append(image)
        }
        return list
    }
    
    init() {
        layer.emitterPosition = .zero
        layer.preservesDepth = true
        layer.renderMode = .oldestLast
        layer.masksToBounds = false
        layer.emitterMode = .points
        layer.emitterShape = .circle
        layer.birthRate = 0
        updateImageCells()
    }
    
    func updateImageCells() {
        let imgs = images.isEmpty ? defaultImages : images
        let count = imgs.count
        layer.emitterCells  = imgs.map({ Emitter.createEmitterCell(name: "cell", image: $0, birthRate: count) })
    }
    
    func setupEmitterPoint(point: CGPoint) {
        layer.emitterPosition = point
    }
    
    func start() {
        layer.birthRate = 1
    }
    
    func stop() {
        layer.birthRate = 0
    }
    
    static func createEmitterCell(name: String, image: UIImage, birthRate: Int) -> CAEmitterCell {
        /// 创建粒子, 并且设置例子相关的属性
        let cell = CAEmitterCell()
        /// 设置粒子速度
        cell.velocity = 1
        cell.velocityRange = 1
        /// 设置例子的大小
        cell.scale = 1
        cell.scaleRange = 0.5
        /// 设置粒子方向
        cell.emissionLongitude = CGFloat.pi * 3
        cell.emissionRange = CGFloat.pi / 6
        /// 设置例子的存活时间
        cell.lifetime = 3
        cell.lifetimeRange = 2.5
        /// 设置粒子旋转
        cell.spin = CGFloat.pi / 2
        cell.spinRange = CGFloat.pi / 4
        /// 设置例子每秒弹出的个数
        cell.birthRate = 5
        cell.alphaRange = 0.75
        cell.alphaSpeed = -0.35
        /// 初始速度
        cell.velocity = 90
        cell.name = name
        
        cell.contents = image.cgImage
        return cell
    }
}
