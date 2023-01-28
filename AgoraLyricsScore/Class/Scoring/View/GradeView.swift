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
    private var gradeItems = [GradeItem]()
    var gradeViewHighlightColors = [UIColor]()
    var gradeViewNormalColor = UIColor.black.withAlphaComponent(0.3)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
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
        progressView.gradeViewNormalColor = gradeViewNormalColor
        progressView.gradeViewHighlightColors = gradeViewHighlightColors
        progressView.updateUI()
    }
    
    func setupGradeItems(gradeItems: [GradeItem]) {
        self.gradeItems = gradeItems
        progressView.gradeItems = gradeItems
    }
    
    func setTitle(title: String) {
        titleLabel.text = title
    }
    
    func setGradeImage(image: UIImage?) {
        gradeImageView.image = image
        gradeImageView.isHidden = image == nil
    }
    
    func setScore(cumulativeScore: Int, totalScore: Int) {
        if totalScore > 0 {
            let progress = Float(cumulativeScore) / Float(totalScore)
            progressView.setProgress(progress: progress)
            scoreLabel.text = "\(cumulativeScore)分"
        }
    }
    
    func reset() {
        scoreLabel.text = "0分"
        setGradeImage(image: nil)
        progressView.reset()
    }
}

class GradeProgressView: UIView {
    fileprivate static let viewHeight: CGFloat = 12
    private let progressBackgroundView = UIView()
    private let gradientLayer = CAGradientLayer()
    private var widthConstraint: NSLayoutConstraint!
    private var labels = [UILabel]()
    fileprivate var gradeViewHighlightColors = [UIColor]()
    fileprivate var gradeViewNormalColor = UIColor.black.withAlphaComponent(0.3)
    fileprivate var gradeItems = [GradeItem]() { didSet{ updateUI() } }
    
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
        
        gradientLayer.startPoint = .init(x: 0, y: 0.5)
        gradientLayer.endPoint = .init(x: 1, y: 0.5)
        gradientLayer.frame = .init(x: 0, y: 0, width: 0, height: GradeProgressView.viewHeight)
        gradientLayer.cornerRadius = GradeProgressView.viewHeight/2
        progressBackgroundView.layer.addSublayer(gradientLayer)
        
        addSubview(progressBackgroundView)

        progressBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        progressBackgroundView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        progressBackgroundView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        progressBackgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        progressBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    fileprivate func updateUI() {
        progressBackgroundView.backgroundColor = gradeViewNormalColor
        gradientLayer.colors = gradeViewHighlightColors.map({ $0.cgColor })
        
        for label in labels {
            label.removeFromSuperview()
        }

        for item in gradeItems {
            let label = UILabel()
            let rate = Float(item.score) / 100
            let x = CGFloat(rate) * bounds.width
            label.textColor = .white
            label.font = .systemFont(ofSize: 10)
            label.text = "| " + item.description
            progressBackgroundView.insertSubview(label, at: 0)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: x).isActive = true
            labels.append(label)
        }
    }
    
    /// 0-1
    fileprivate func setProgress(progress: Float) {
        let constant = bounds.width * CGFloat(progress)
        gradientLayer.frame = .init(x: 0, y: 0, width: constant, height: GradeProgressView.viewHeight)
        if progress > 0.8 { /** 大于80%有多种颜色 **/
            gradientLayer.colors = gradeViewHighlightColors.map({ $0.cgColor })
        }
        else {
            if gradeViewHighlightColors.count > 2 {
                let colors = [gradeViewHighlightColors[0], gradeViewHighlightColors[1]]
                gradientLayer.colors = colors.map({ $0.cgColor })
            }
        }
    }
    
    fileprivate func reset() {
        widthConstraint.constant = 0
    }
}
