//
//  QiangChangScoringView.swift
//  Demo
//
//  Created by ZYP on 2023/9/1.
//

import UIKit

protocol QiangChangScoringViewDelegate: NSObjectProtocol {
    func qiangChangScoringViewDidTap(action: QiangChangScoringView.Action)
}

class QiangChangScoringView: UIView {
    private let lyricsLabel = UILabel()
    private let scoreLabel = UILabel()
    private let qiangBtn = UIButton()
    private let qieBtn = UIButton()
    private let okBtn = UIButton()
    let voiceChangeSwitch = UISwitch()
    let scoreLevelTextField = UITextField()
    let scoreOffsetTextField = UITextField()
    
    weak var delegate: QiangChangScoringViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        voiceChangeSwitch.isHidden = true
        scoreLevelTextField.isHidden = true
        scoreOffsetTextField.isHidden = true
        backgroundColor = .white
        scoreLabel.textColor = .black
        scoreLabel.numberOfLines = 0
        scoreLabel.textAlignment = .center
        lyricsLabel.textColor = .black
        lyricsLabel.numberOfLines = 0
        lyricsLabel.textAlignment = .center
        qiangBtn.setTitle("抢歌", for: .normal)
        qiangBtn.backgroundColor = .blue
        okBtn.setTitle("唱完", for: .normal)
        okBtn.backgroundColor = .blue
        okBtn.isHidden = true
        qieBtn.setTitle("切歌", for: .normal)
        qieBtn.backgroundColor = .red
        scoreLevelTextField.placeholder = "scoreLevel [0, 100] default: 30"
        scoreLevelTextField.borderStyle = .roundedRect
        scoreLevelTextField.clearButtonMode = .always
        scoreOffsetTextField.placeholder = "scoreOffset [-100, 100] default:0"
        scoreOffsetTextField.borderStyle = .roundedRect
        scoreOffsetTextField.clearButtonMode = .always
        
        addSubview(lyricsLabel)
        addSubview(qiangBtn)
        addSubview(okBtn)
        addSubview(qieBtn)
        addSubview(scoreLabel)
        addSubview(voiceChangeSwitch)
        addSubview(scoreLevelTextField)
        addSubview(scoreOffsetTextField)
        
        lyricsLabel.translatesAutoresizingMaskIntoConstraints = false
        lyricsLabel.translatesAutoresizingMaskIntoConstraints = false
        qiangBtn.translatesAutoresizingMaskIntoConstraints = false
        okBtn.translatesAutoresizingMaskIntoConstraints = false
        qieBtn.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        voiceChangeSwitch.translatesAutoresizingMaskIntoConstraints = false
        scoreLevelTextField.translatesAutoresizingMaskIntoConstraints = false
        scoreOffsetTextField.translatesAutoresizingMaskIntoConstraints = false
        
        lyricsLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        lyricsLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        lyricsLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        
        scoreLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scoreLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scoreLabel.topAnchor.constraint(equalTo: lyricsLabel.bottomAnchor).isActive = true
        
        qiangBtn.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        qiangBtn.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        qiangBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
        qiangBtn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        okBtn.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        okBtn.topAnchor.constraint(equalTo: qiangBtn.bottomAnchor, constant: 20).isActive = true
        okBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
        okBtn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        qieBtn.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        qieBtn.topAnchor.constraint(equalTo: topAnchor, constant: 200).isActive = true
        qieBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
        qieBtn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        voiceChangeSwitch.topAnchor.constraint(equalTo: qieBtn.bottomAnchor).isActive = true
        voiceChangeSwitch.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        
        scoreLevelTextField.leftAnchor.constraint(equalTo: qieBtn.rightAnchor).isActive = true
        scoreLevelTextField.topAnchor.constraint(equalTo: qieBtn.topAnchor).isActive = true
        scoreLevelTextField.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        scoreOffsetTextField.leftAnchor.constraint(equalTo: qieBtn.rightAnchor).isActive = true
        scoreOffsetTextField.topAnchor.constraint(equalTo: scoreLevelTextField.bottomAnchor).isActive = true
        scoreOffsetTextField.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    private func commonInit() {
        qiangBtn.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        okBtn.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        qieBtn.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        endEditing(true)
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        if sender == qiangBtn {
            qiangBtn.isHidden = true
            okBtn.isHidden = false
            okBtn.setTitle("唱完", for: .normal)
            delegate?.qiangChangScoringViewDidTap(action: .qiang)
            return
        }
        if sender == okBtn {
            qiangBtn.isHidden = false
            okBtn.isHidden = true
            delegate?.qiangChangScoringViewDidTap(action: .ok)
            return
        }
        if sender == qieBtn {
            qiangBtn.isHidden = false
            okBtn.isHidden = true
            delegate?.qiangChangScoringViewDidTap(action: .qie)
            return
        }
    }
    
    func updateOkTime(num: Int) {
        okBtn.setTitle("唱完\(num)", for: .normal)
    }
    
    func setLiric(text: String) {
        lyricsLabel.text = text
    }
    
    func setScore(string: String, color: UIColor = .black) {
        scoreLabel.text = string
        scoreLabel.textColor = color
    }
    
    func setCompleted() {
        qiangBtn.isHidden = false
        okBtn.isHidden = true
    }
}

extension QiangChangScoringView {
    enum Action {
        case qiang
        case ok
        case qie
    }
}
