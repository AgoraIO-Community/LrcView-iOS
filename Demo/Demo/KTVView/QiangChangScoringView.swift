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
    private let qiangBtn = UIButton()
    private let okBtn = UIButton()
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
        backgroundColor = .white
        lyricsLabel.textColor = .black
        lyricsLabel.numberOfLines = 0
        lyricsLabel.textAlignment = .center
        qiangBtn.setTitle("抢歌", for: .normal)
        qiangBtn.backgroundColor = .blue
        okBtn.setTitle("唱完", for: .normal)
        okBtn.backgroundColor = .blue
        okBtn.isHidden = true
        
        addSubview(lyricsLabel)
        addSubview(qiangBtn)
        addSubview(okBtn)
        
        lyricsLabel.translatesAutoresizingMaskIntoConstraints = false
        qiangBtn.translatesAutoresizingMaskIntoConstraints = false
        okBtn.translatesAutoresizingMaskIntoConstraints = false
        
        lyricsLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        lyricsLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        lyricsLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        
        qiangBtn.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        qiangBtn.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        qiangBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
        qiangBtn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        okBtn.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        okBtn.topAnchor.constraint(equalTo: qiangBtn.bottomAnchor, constant: 20).isActive = true
        okBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
        okBtn.heightAnchor.constraint(equalToConstant: 45).isActive = true
    }
    
    private func commonInit() {
        qiangBtn.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        okBtn.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
    }

    @objc func buttonTap(_ sender: UIButton) {
        if sender == qiangBtn {
            qiangBtn.isHidden = true
            okBtn.isHidden = false
            okBtn.setTitle("唱完", for: .normal)
            delegate?.qiangChangScoringViewDidTap(action: .qiang)
        }
        else {
            qiangBtn.isHidden = false
            okBtn.isHidden = true
            delegate?.qiangChangScoringViewDidTap(action: .ok)
        }
    }
    
    func updateOkTime(num: Int) {
        okBtn.setTitle("唱完\(num)", for: .normal)
    }
    
    func setLiric(text: String) {
        lyricsLabel.text = text
    }
}

extension QiangChangScoringView {
    enum Action {
        case qiang
        case ok
    }
}
