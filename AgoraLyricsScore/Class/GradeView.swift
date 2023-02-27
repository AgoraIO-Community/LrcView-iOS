//
//  GradeView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/4.
//

import UIKit

/// 等级视图
public class GradeView: UIView {
    private let titleLabel = UILabel()
    private let gradeImageView = UIImageView()
    private let scoreLabel = UILabel()
    private let progressView = GradeProgressView()
    private var gradeItems: [GradeItem]!
    private var gradeScores: [Int]!
    private let logTag = "GradeView"
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    private func setupIfNeed() {
        if gradeItems == nil {
            let items = createData()
            gradeItems = items
            gradeScores = items.map({ $0.score })
            progressView.setup(gradeItems: gradeItems)
        }
    }
    
    @objc public func setTitle(title: String) {
        titleLabel.text = title
    }
    
    @objc public func setScore(cumulativeScore: Int, totalScore: Int) {
        setupIfNeed()
        
        if totalScore > 0 {
            let progress = Float(cumulativeScore) / Float(totalScore)
            progressView.setProgress(progress: progress)
            scoreLabel.text = "\(cumulativeScore)分"
            if let gradeIndex = totalGradeIndex(cumulativeScore: cumulativeScore,
                                                totalScore: totalScore,
                                                gradeScores: gradeScores) {
                let image = gradeItems[gradeIndex].image
                setGradeImage(image: image)
            }
            else {
                setGradeImage(image: nil)
            }
        }
        
        if totalScore < 100 {
            Log.error(error: "totalScore invalid", tag: logTag)
        }
    }
    
    @objc public func reset() {
        scoreLabel.text = "0分"
        setGradeImage(image: nil)
        progressView.reset()
    }
    
    private func createData() -> [GradeItem] {
        return [.init(score: 60, description: "C", image: Bundle.currentBundle.image(name: "icon-C")!),
                .init(score: 70, description: "B", image: Bundle.currentBundle.image(name: "icon-B")!),
                .init(score: 80, description: "A", image: Bundle.currentBundle.image(name: "icon-A")!),
                .init(score: 90, description: "S", image: Bundle.currentBundle.image(name: "icon-S")!)]
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
    
    private func setGradeImage(image: UIImage?) {
        gradeImageView.image = image
        gradeImageView.isHidden = image == nil
    }
    
    /// 计算分数等级 当一句结束的时候回调
    /// - Parameter score: 每一句的分数
    /// - Parameter gradeScores: 等级参考分数
    /// - Returns: 等级索引, `nil`表示没有匹配上
    func totalGradeIndex(cumulativeScore: Int,
                         totalScore: Int,
                         gradeScores: [Int]) -> Int? {
        guard !gradeScores.isEmpty else {
            return nil
        }
        
        if cumulativeScore < 0 {
            return nil
        }
        
        let ratio = Float(cumulativeScore)/Float(totalScore)
        if ratio > 1 {
            return gradeScores.count - 1
        }
        
        if ratio < Float(gradeScores.first!) / 100 {
            return nil
        }
        
        var last: Int? = nil
        for item in gradeScores.enumerated() {
            if ratio == Float(item.element) / 100 {
                return item.offset
            }
            if ratio >= Float(item.element) / 100 {
                last = item.offset
            }
        }
        return last
    }
}

class GradeProgressView: UIView {
    fileprivate static let viewHeight: CGFloat = 12
    private let progressBackgroundView = UIView()
    private let gradientLayer = CAGradientLayer()
    private var widthConstraint: NSLayoutConstraint!
    private var labels = [UILabel]()
    /// 等级视图的正常颜色
    private var gradeViewNormalColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    /// 等级视图的高亮颜色 (渐变色)
    private var gradeViewHighlightColors: [UIColor] = [UIColor.colorWithHex(hexStr: "#99F5FF"),
                                                       UIColor.colorWithHex(hexStr: "#1B6FFF"),
                                                       UIColor.colorWithHex(hexStr: "#D598FF")]
    fileprivate var gradeItems: [GradeItem]!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        progressBackgroundView.backgroundColor = gradeViewNormalColor
        gradientLayer.colors = gradeViewHighlightColors.map({ $0.cgColor })
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
    var lebelLeftConstraints = [NSLayoutConstraint]()
    
    func setup(gradeItems: [GradeItem]) {
        guard frame.size.width > 0 else {
            return
        }
        
        for label in labels {
            label.removeFromSuperview()
        }
        for item in gradeItems {
            let label = UILabel()
            let rate = Float(item.score) / 100
            let x = CGFloat(rate) * (frame.size.width)
            label.textColor = .white
            label.font = .systemFont(ofSize: 10)
            label.text = "| " + item.description
            progressBackgroundView.insertSubview(label, at: 0)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            let lebelLeftConstraint = label.leftAnchor.constraint(equalTo: leftAnchor, constant: x)
            lebelLeftConstraint.isActive = true
            lebelLeftConstraints.append(lebelLeftConstraint)
            labels.append(label)
        }
    }
    
    /// 0-1
    fileprivate func setProgress(progress: Float) {
        let constant = bounds.width * CGFloat(progress)
        gradientLayer.frame = .init(x: 0, y: 0, width: constant, height: GradeProgressView.viewHeight)
        
        /**
         渐变色
         <=0.1 -> 单色
         >0.1 < 0.8 双色
         >= 0.8 三色
         **/
        if progress > 0, progress <= 0.1 {
            if !gradeViewHighlightColors.isEmpty {
                let colors = [gradeViewHighlightColors[0], gradeViewHighlightColors[0]]
                gradientLayer.colors = colors.map({ $0.cgColor })
            }
        }
        else if progress > 0.1, progress < 0.8 {
            if gradeViewHighlightColors.count >= 2 {
                let colors = [gradeViewHighlightColors[0], gradeViewHighlightColors[1]]
                gradientLayer.colors = colors.map({ $0.cgColor })
            }
        }
        else {
            gradientLayer.colors = gradeViewHighlightColors.map({ $0.cgColor })
        }
    }
    
    fileprivate func reset() {
        setProgress(progress: 0)
    }
}

public struct GradeItem {
    public let score: Int
    public let description: String
    public let image: UIImage
}
