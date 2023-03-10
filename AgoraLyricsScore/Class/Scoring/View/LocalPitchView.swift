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
    private var indicatedCenterYConstant: CGFloat = 0.0
    static let scoreAnimateWidth: CGFloat = 30
    /// 游标的起始位置
    var defaultPitchCursorX: CGFloat = 100
    /// 是否隐藏粒子动画效果
    var particleEffectHidden: Bool = false
    /** 游标偏移量(X轴) 游标的中心到竖线中心的距离
     - 等于0：游标中心点和竖线中线点重合
     - 小于0: 游标向左偏移
     - 大于0：游标向向偏移 **/
    var localPitchCursorOffsetX: CGFloat = -3 { didSet { updateUI() } }
    /// 游标的图片
    var localPitchCursorImage: UIImage? = nil { didSet { updateUI() } }
    var emitterImages: [UIImage]? {
        didSet {
            emitter.images = emitterImages
        }
    }
    private var indicatedViewCenterYConstraint, indicatedViewCenterXConstraint: NSLayoutConstraint!
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
        
        indicatedViewCenterXConstraint = indicatedView.centerXAnchor.constraint(equalTo: verticalLineView.centerXAnchor, constant: localPitchCursorOffsetX)
        indicatedViewCenterYConstraint = indicatedView.centerYAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        indicatedViewCenterXConstraint.isActive = true
        indicatedViewCenterYConstraint.isActive = true
    }
    
    private func updateUI() {
        indicatedViewCenterXConstraint.constant = localPitchCursorOffsetX
        indicatedView.image = localPitchCursorImage ?? Bundle.currentBundle.image(name: "icon_trangle")
    }
    
    /// 设置游标位置
    /// - Parameter y: 从top到bottom方向上的距离
    func setIndicatedViewY(y: CGFloat) {
        let constant = (bounds.height - y) * -1
        let duration: TimeInterval = indicatedCenterYConstant < constant ? 0.05 : 0.15
        indicatedCenterYConstant = constant
        indicatedViewCenterYConstraint.constant = constant
        UIView.animate(withDuration: duration, delay: 0, options: []) { [weak self] in
            self?.layoutIfNeeded()
        }
        emitter.setupEmitterPoint(point: .init(x: defaultPitchCursorX-3, y: y))
    }
      
    func startEmitter() {
        if particleEffectHidden { return }
        emitter.start()
    }
    
    func stopEmitter() {
        emitter.stop()
    }
    
    func reset() {
        setIndicatedViewY(y: bounds.height)
        stopEmitter()
        emitter.reset()
    }
}

class Emitter {
    var layer = CAEmitterLayer()
    var images: [UIImage]? {
        didSet {
            updateLayer()
        }
    }
    private var count = 0
    private var lastPoint: CGPoint = .zero
    private let logTag = "Emitter"
    
    var defaultImages: [UIImage] {
        var list = [UIImage]()
        for i in 1...8 {
            if let image = Bundle.currentBundle.image(name: "star\(i)") {
                list.append(image)
            }
            else {
                Log.error(error: "image == nil", tag: logTag)
            }
        }
        return list
    }
    
    init() {
        updateLayer()
    }
    
    func updateLayer() {
        let superLayer = layer.superlayer
        layer.removeFromSuperlayer()
        
        layer = CAEmitterLayer()
        superLayer?.addSublayer(layer)
        layer.emitterPosition = .zero
        layer.preservesDepth = true
        layer.renderMode = .oldestLast
        layer.masksToBounds = false
        layer.emitterMode = .points
        layer.emitterShape = .circle
        layer.birthRate = 0
        layer.emitterPosition = lastPoint
        let imgs = (images != nil) ? images! : defaultImages
        let count = imgs.count
        layer.emitterCells = imgs.enumerated().map({ Emitter.createEmitterCell(name: "cell", image: $0.1, birthRate: count) })
    }
    
    func setCount() {
        count += 1
        if count >= 150 {
            count = 0
            updateLayer()
        }
    }
    
    func setupEmitterPoint(point: CGPoint) {
        lastPoint = point
        layer.emitterPosition = point
    }
    
    func start() {
        setCount()
        layer.birthRate = 1
    }
    
    func stop() {
        setCount()
        layer.birthRate = 0
    }
    
    func reset(){
        count = 0
        updateLayer()
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
        /// 设置粒子的存活时间
        cell.lifetime = 100
        cell.lifetimeRange = 0
        /// 设置粒子旋转
        cell.spin = CGFloat.pi / 2
        cell.spinRange = CGFloat.pi / 4
        /// 设置粒子每秒弹出的个数
        cell.birthRate = 4
        cell.alphaRange = 0.75
        cell.alphaSpeed = -0.35
        /// 初始速度
        cell.velocity = 90
        cell.name = name
        cell.isEnabled = true
        cell.contents = image.cgImage
        return cell
    }
}
