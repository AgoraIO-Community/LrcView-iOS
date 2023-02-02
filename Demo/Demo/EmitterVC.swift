//
//  EmitterVC.swift
//  Demo
//
//  Created by ZYP on 2023/1/5.
//

import UIKit

class EmitterVC: UIViewController {

    let emitter = Emitter()
    var start = true
    private var timer = GCDTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        emitter.setupEmitterPoint(point: .init(x: 300, y: 300))
        view.layer.addSublayer(emitter.layer)
        
        timer.scheduledMillisecondsTimer(withName: "EmitterVC", countDown: 1000000, milliseconds: 1000, queue: .main) { [weak self](_, time) in
            guard let self = self else { return }
            self.start ? self.emitter.stop() : self.emitter.start()
            self.start = !self.start
        }
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        timer.scheduledMillisecondsTimer(withName: "EmitterVC", countDown: 1000000, milliseconds: 1000, queue: .main) { [weak self](_, time) in
//            guard let self = self else { return }
//            self.start ? self.emitter.stop() : self.emitter.start()
//            self.start = !self.start
//        }
//    }
    
}

class Emitter {
    let layer = CAEmitterLayer()
    var images: [UIImage]? {
        didSet {
            updateImageCells()
        }
    }
    private let logTag = "Emitter"
    
    var defaultImages: [UIImage] {
        var list = [UIImage]()
        for i in 1...8 {
            let image = UIImage(named: "star\(i)")!
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
        let imgs = (images != nil) ? images! : defaultImages
        let count = imgs.count
        layer.emitterCells = imgs.enumerated().map({ Emitter.createEmitterCell(name: "cell", image: $0.1, birthRate: count) })
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
        /// 设置粒子的存活时间
        cell.lifetime = 0.5
        cell.lifetimeRange = 0.2
        /// 设置粒子旋转
        cell.spin = CGFloat.pi / 2
        cell.spinRange = CGFloat.pi / 4
        /// 设置例子每秒弹出的个数
        cell.birthRate = Float(birthRate)
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

