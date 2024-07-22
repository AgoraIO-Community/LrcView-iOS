//
//  SearchVC.swift
//  Demo
//
//  Created by ZYP on 2023/2/7.
//

import UIKit
import AgoraRtcKit

protocol SearchVCDelegate: NSObjectProtocol {
    func searchVCDidSelected(songCode: Int)
}

class SearchVC: UIViewController {
    let tableview = UITableView()
    let textFeild = UITextField()
    var list = [AgoraMusic]()
    weak var delegate: SearchVCDelegate?
    weak var mcc: AgoraMusicContentCenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    func setup(mcc: AgoraMusicContentCenter) {
        self.mcc = mcc
        mcc.register(self)
        list = []
    }
    
    func append(musics: [AgoraMusic]) {
        list.append(contentsOf: musics)
        tableview.reloadData()
    }

    func setupUI() {
        view.addSubview(textFeild)
        view.addSubview(tableview)
        tableview.translatesAutoresizingMaskIntoConstraints = false
        textFeild.translatesAutoresizingMaskIntoConstraints = false
        
        textFeild.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        textFeild.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -100).isActive = true
        textFeild.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40).isActive = true
        
        tableview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    func commonInit() {
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.reloadData()
    }
}

extension SearchVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = list[indexPath.row]
        cell.textLabel?.text = item.name + "[\(item.singer)][\(item.songCode)]"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = list[indexPath.row]
        delegate?.searchVCDidSelected(songCode: item.songCode)
    }
}

extension SearchVC: AgoraMusicContentCenterEventDelegate {
    func onLyricInfo(_ requestId: String, songCode: Int, lyricInfo: AgoraLyricInfo?, errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onMusicChartsResult(_ requestId: String, result: [AgoraMusicChartInfo], errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onMusicCollectionResult(_ requestId: String, result: AgoraMusicCollection, errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onLyricResult(_ requestId: String, songCode: Int, lyricUrl: String?, errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onSongSimpleInfoResult(_ requestId: String, songCode: Int, simpleInfo: String?, errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
    
    func onPreLoadEvent(_ requestId: String, songCode: Int, percent: Int, lyricUrl: String?, status: AgoraMusicContentCenterPreloadStatus, errorCode: AgoraMusicContentCenterStatusCode) {
        
    }
}



