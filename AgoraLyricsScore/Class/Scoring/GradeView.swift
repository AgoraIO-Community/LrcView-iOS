//
//  GradeView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/4.
//

import UIKit

class GradeView: UIView {
    private let titleLabel = UILabel()
    private let gradeImageView = UIImageView()
    private let scoreLabel = UILabel()
    private let progressView = GradeProgressView()
    /// 歌曲预设总分
    var totalScore: Int = 0
    /// 累计分
    private var cumulativeScore: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        gradeImageView.image = Bundle.currentBundle.image(name: "icon-C")
        scoreLabel.text = "0分"
        scoreLabel.textColor = .white
        scoreLabel.font = .systemFont(ofSize: 11)
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = UIColor.colorWithHex(hexStr: "#979CBB")
        addSubview(titleLabel)
        addSubview(gradeImageView)
        addSubview(scoreLabel)
        addSubview(progressView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        gradeImageView.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        scoreLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scoreLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        gradeImageView.rightAnchor.constraint(equalTo: scoreLabel.leftAnchor, constant: -2).isActive = true
        gradeImageView.centerYAnchor.constraint(equalTo: scoreLabel.centerYAnchor).isActive = true
        
        progressView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        progressView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: GradeProgressView.viewHeight).isActive = true
        progressView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    /// 当父视图布局完成时调用
    func updateUI() {
        progressView.updateUI()
    }
    
    func setTitle(title: String) {
        titleLabel.text = title
    }
    
    func addScore(score: Int) {
        cumulativeScore += score
        if totalScore > 0 {
            let progress = Float(cumulativeScore) / Float(totalScore)
            progressView.setProgress(progress: progress)
            scoreLabel.text = "\(cumulativeScore)分"
        }
    }
    
    func reset() {
        totalScore = 0
        cumulativeScore = 0
        scoreLabel.text = "0分"
    }
}

class GradeProgressView: UIView {
    fileprivate static let viewHeight: CGFloat = 12
    private let progressBackgroundView = UIView()
    private let gradientLayer = CAGradientLayer()
    private var widthConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        progressBackgroundView.layer.masksToBounds = true
        progressBackgroundView.layer.cornerRadius = GradeProgressView.viewHeight / 2
        progressBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        gradientLayer.colors = [UIColor.yellow.cgColor, UIColor.red.cgColor]
        gradientLayer.startPoint = .init(x: 0, y: 0.5)
        gradientLayer.endPoint = .init(x: 1, y: 0.5)
        gradientLayer.frame = .init(x: 0, y: 0, width: 0, height: GradeProgressView.viewHeight)
        progressBackgroundView.layer.addSublayer(gradientLayer)
        
        addSubview(progressBackgroundView)
        
        

        progressBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        progressBackgroundView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        progressBackgroundView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        progressBackgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        progressBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        

    }
    
    fileprivate func updateUI() {
//        gradientLayer.frame = bounds
    }
    
    /// 0-1
    fileprivate func setProgress(progress: Float) {
        let constant = bounds.width * CGFloat(progress)
        gradientLayer.frame = .init(x: 0, y: 0, width: constant, height: GradeProgressView.viewHeight)
    }
    
    fileprivate func reset() {
        widthConstraint.constant = 0
    }
}
