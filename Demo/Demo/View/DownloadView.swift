//
//  DownloadView.swift
//  Demo
//
//  Created by ZYP on 2023/12/14.
//

import UIKit

protocol DownloadViewDelegate: NSObjectProtocol {
    func downloadViewDidTapAction(action: DownloadView.Action, info: DownloadView.Info?)
}

class DownloadView: UIView {
    let tableView = UITableView(frame: .zero)
    let allButton = UIButton()
    let addOneButton = UIButton()
    let clearButton = UIButton()
    var list = [Info]()
    weak var delegate: DownloadViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        backgroundColor = .white
        allButton.setTitle("新增所有任务", for: .normal)
        addOneButton.setTitle("新增任务", for: .normal)
        clearButton.setTitle("清空本地", for: .normal)
        
        allButton.backgroundColor = .red
        addOneButton.backgroundColor = .red
        clearButton.backgroundColor = .red
        
        addSubview(allButton)
        addSubview(addOneButton)
        addSubview(clearButton)
        addSubview(tableView)
        
        allButton.translatesAutoresizingMaskIntoConstraints = false
        addOneButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: centerYAnchor, constant: 100).isActive = true
        
        allButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        allButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 5).isActive = true
        
        addOneButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        addOneButton.topAnchor.constraint(equalTo: allButton.bottomAnchor, constant: 5).isActive = true
        
        clearButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        clearButton.topAnchor.constraint(equalTo: addOneButton.bottomAnchor, constant: 5).isActive = true
    }
    
    func commonInit() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        allButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        addOneButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        if sender == allButton {
            delegate?.downloadViewDidTapAction(action: .addAll, info: nil)
            return
        }
        if sender == addOneButton {
            delegate?.downloadViewDidTapAction(action: .addOne, info: nil)
            return
        }
        if sender == clearButton {
            delegate?.downloadViewDidTapAction(action: .clear, info: nil)
            return
        }
    }
    
    func addInfos(infos: [Info]) {
        list.append(contentsOf: infos)
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: list.count-1, section: 0), at: .bottom, animated: false)
    }
    
    func reloadData() {
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: list.count-1, section: 0), at: .bottom, animated: false)
    }
    
    func getInfo(requestId: Int) -> Info? {
        return list.first(where: { $0.requestId == requestId })
    }
}

extension DownloadView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = list[indexPath.row]
        let percentage = Int(item.progress * 100)
        cell.textLabel?.text = "(\(item.requestId))\(item.fileName)   [\(percentage)]\(item.state.name)"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = list[indexPath.row]
        delegate?.downloadViewDidTapAction(action: .cancel, info: item)
    }
}

extension DownloadView {
    
    enum Action {
        case addOne
        case addAll
        case cancel
        case clear
    }
    
    enum State {
        case created
        case progress
        case doneSuccess
        case doneFail
        case canceled
        
        var name: String {
            switch self {
            case .created:
                return "created"
            case .progress:
                return "progress"
            case .doneSuccess:
                return "Success"
            case .doneFail:
                return "Fail"
            case .canceled:
                return "canceled"
            }
        }
    }
    
    class Info {
        let requestId: Int
        let urlString: String
        var state = State.created
        var progress: Float = 0
        
        init(requestId: Int, urlString: String) {
            self.requestId = requestId
            self.urlString = urlString
        }
        
        var fileName: String {
            urlString.components(separatedBy: "/").last ?? ""
        }
    }
}
