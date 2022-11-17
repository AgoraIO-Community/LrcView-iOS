//
//  BottomView.swift
//  AgoraKaraokeScore
//
//  Created by ZYP on 2022/10/13.
//

import UIKit

protocol BottomViewDelegate: NSObjectProtocol {
    func bottomViewDidTap(actionType: BottomView.ActionType)
}

class BottomView: UIView {
    weak var delegate: BottomViewDelegate?
    private let playButton = UIButton()
    private let replayButton = UIButton()
    private let skipButton = UIButton()
    private let scoreLabel = UILabel()
    private let indicatorView = UIActivityIndicatorView(style: .medium)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .yellow
        
        playButton.setTitle("播放", for: .normal)
        playButton.setTitleColor(.blue, for: .normal)
        playButton.titleLabel?.font = .systemFont(ofSize: 15)
        playButton.addTarget(self, action: #selector(clickPlayButton(sender:)), for: .touchUpInside)
        playButton.isEnabled = false
        
        replayButton.setTitle("重唱", for: .normal)
        replayButton.setTitleColor(.systemPink, for: .normal)
        replayButton.titleLabel?.font = .systemFont(ofSize: 15)
        replayButton.addTarget(self, action: #selector(clickReplayButton), for: .touchUpInside)
        replayButton.isEnabled = false
        
        skipButton.setTitle("跳过前奏", for: .normal)
        skipButton.setTitleColor(.systemPink, for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 15)
        skipButton.addTarget(self, action: #selector(clickSkipButton), for: .touchUpInside)
        
        indicatorView.hidesWhenStopped = true
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(playButton)
        addSubview(replayButton)
        addSubview(scoreLabel)
        addSubview(indicatorView)
        addSubview(skipButton)
        
        playButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -25).isActive = true
        playButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        scoreLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        scoreLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        
        replayButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 25).isActive = true
        replayButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        replayButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        replayButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        skipButton.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 100).isActive = true
        skipButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        skipButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        skipButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        indicatorView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func clickPlayButton(sender: UIButton) {
        delegate?.bottomViewDidTap(actionType: .play)
    }
    
    @objc private func clickReplayButton() {
        delegate?.bottomViewDidTap(actionType: .replay)
    }
    
    @objc private func clickSkipButton() {
        delegate?.bottomViewDidTap(actionType: .skip)
    }
    
    func enablePlay(enable: Bool) {
        playButton.isEnabled = enable
        replayButton.isEnabled = enable
    }
    
    func startLoading() {
        indicatorView.startAnimating()
    }
    
    func stopLoading() {
        indicatorView.stopAnimating()
    }
}

extension BottomView {
    enum ActionType {
        case play
        case replay
        case skip
    }
}
