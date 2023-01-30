//
//  ConsoleView.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/1/30.
//

import UIKit

/// use for debug only
class ConsoleView: UIView {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .systemFont(ofSize: 9)
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        label.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(text: String) {
        label.text = text
    }
}
