//
//  PanelView.swift
//  Demo
//
//  Created by ZYP on 2023/7/3.
//

import UIKit

protocol PanelViewDelegate: NSObjectProtocol {
    func panelViewDidTapAction(action: PanelView.Action)
}

class PanelView: UIView {
    let skipButton = UIButton()
    let setButton = UIButton()
    let quickButton = UIButton()
    let changeButton = UIButton()
    let pauseButton = UIButton()
    let searchButton = UIButton()
    weak var delegate: PanelViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        skipButton.setTitle("跳过前奏", for: .normal)
        setButton.setTitle("设置参数", for: .normal)
        changeButton.setTitle("切歌", for: .normal)
        quickButton.setTitle("退出", for: .normal)
        pauseButton.setTitle("暂停", for: .normal)
        pauseButton.setTitle("继续", for: .selected)
        searchButton.setTitle("点歌", for: .normal)
        skipButton.backgroundColor = .red
        setButton.backgroundColor = .red
        changeButton.backgroundColor = .red
        quickButton.backgroundColor = .red
        pauseButton.backgroundColor = .red
        searchButton.backgroundColor = .red
        
        backgroundColor = .black
        addSubview(skipButton)
        addSubview(setButton)
        addSubview(changeButton)
        addSubview(quickButton)
        addSubview(pauseButton)
        addSubview(searchButton)
        
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        setButton.translatesAutoresizingMaskIntoConstraints = false
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        quickButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        
        skipButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 100).isActive = true
        skipButton.topAnchor.constraint(equalTo: topAnchor, constant: 30).isActive = true
        
        setButton.leftAnchor.constraint(equalTo: skipButton.rightAnchor, constant: 45).isActive = true
        setButton.topAnchor.constraint(equalTo: topAnchor, constant: 30).isActive = true
        
        changeButton.leftAnchor.constraint(equalTo: skipButton.leftAnchor).isActive = true
        changeButton.topAnchor.constraint(equalTo: setButton.bottomAnchor, constant: 30).isActive = true
        
        quickButton.leftAnchor.constraint(equalTo: setButton.leftAnchor).isActive = true
        quickButton.topAnchor.constraint(equalTo: setButton.bottomAnchor, constant: 30).isActive = true
        
        pauseButton.leftAnchor.constraint(equalTo: skipButton.leftAnchor).isActive = true
        pauseButton.topAnchor.constraint(equalTo: changeButton.bottomAnchor, constant: 30).isActive = true
        
        searchButton.leftAnchor.constraint(equalTo: pauseButton.leftAnchor).isActive = true
        searchButton.topAnchor.constraint(equalTo: pauseButton.bottomAnchor, constant: 30).isActive = true
    }

    func commonInit() {
        setButton.tag = 0
        changeButton.tag = 1
        quickButton.tag = 2
        pauseButton.tag = 3
        skipButton.tag = 4
        searchButton.tag = 5
        
        skipButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        setButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        changeButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        quickButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        let action = Action(rawValue: sender.tag)!
        delegate?.panelViewDidTapAction(action: action)
    }
    
}

extension PanelView {
    enum Action: Int {
        case set = 0
        case change
        case quick
        case pause
        case skip
        case search
    }
}
