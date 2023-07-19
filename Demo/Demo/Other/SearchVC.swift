//
//  SearchVC.swift
//  Demo
//
//  Created by ZYP on 2023/2/7.
//

import UIKit
import AgoraRtcKit

protocol SearchVCDelegate: NSObjectProtocol {
    func searchVCDidSelected(music: AgoraMusic, lyricType: Int)
}

class SearchVC: UIViewController {
    let tableview = UITableView()
    let textFeild = UITextField()
    var list = [AgoraMusic]()
    weak var delegate: SearchVCDelegate?
    weak var rtcManager: RTCManager!
    var page = 1
    var isLoading = false
    var hasNoData = false
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    func setup(rtcManager: RTCManager) {
        self.rtcManager = rtcManager
        rtcManager.songListDelegate = self
    }
    
    func update(musics: [AgoraMusic]) {
        list += musics
        tableview.reloadData()
    }

    func setupUI() {
        view.backgroundColor = .black
        textFeild.returnKeyType = .search
        textFeild.borderStyle = .roundedRect
        textFeild.placeholder = "输入关键字"
        
        view.addSubview(textFeild)
        view.addSubview(tableview)
        tableview.translatesAutoresizingMaskIntoConstraints = false
        textFeild.translatesAutoresizingMaskIntoConstraints = false
        
        textFeild.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        textFeild.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        textFeild.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        tableview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableview.topAnchor.constraint(equalTo: textFeild.bottomAnchor).isActive = true
        tableview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    func commonInit() {
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.reloadData()
        textFeild.delegate = self
    }
    
    func showSelectedView(music: AgoraMusic) {
        let lyricList = music.lyricList.map({ $0.intValue })
        let vc = UIAlertController(title: "选择打分类型", message: nil, preferredStyle: .actionSheet)
        var actions = [UIAlertAction]()
        for type in lyricList {
            let action = UIAlertAction(title: type.name, style: .default) { [weak self](action) in
                self?.delegate?.searchVCDidSelected(music: music, lyricType: type)
                self?.dismiss(animated: true)
            }
            vc.addAction(action)
        }
        
        let action = UIAlertAction(title: "取消", style: .destructive)
        vc.addAction(action)
        present(vc, animated: true)
    }
}

extension SearchVC: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, RTCManagerSongListDelegate {
    func RTCManagerDidRecvSearch(result: AgoraMusicCollection) {
        isLoading = false
        update(musics: result.musicList)
        if result.musicList.isEmpty {
            hasNoData = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        page = 1
        hasNoData = false
        list = []
        tableview.reloadData()
        rtcManager.search(keyWord: textField.text!, page: page)
        isLoading = true
        return textField.resignFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let item = list[indexPath.row]
        cell.textLabel?.text = item.name + "[\(item.singer)][\(item.songCode)]"
        cell.detailTextLabel?.text = item.lyricList.map ({ $0.stringValue }).joined(separator:"/")
        cell.accessoryType = .disclosureIndicator
        
        if !isLoading, !hasNoData, indexPath.row == list.count - 1 {
            page += 1
            rtcManager.search(keyWord: textFeild.text!, page: page)
            isLoading = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = list[indexPath.row]
        showSelectedView(music: item)
    }
}

extension Int {
    var name: String {
        switch self {
        case 0:
            return "xml"
        case 1:
            return "lrc"
        case 2:
            return "webrtt(not supported)"
        case 3:
            return "xml + pitch"
        case 4:
            return "lrc + pitch"
        default:
            return "unknow"
        }
    }
}
