//
//  SongListVC.swift
//  Demo
//
//  Created by ZYP on 2023/3/30.
//

import UIKit

protocol SongListVCDelegate: NSObjectProtocol {
    func songListVCDidSelectedSong(song: SongListVC.Song)
}

class SongListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var songs = [Song]()
    let tableview = UITableView(frame: .zero, style: .grouped)
    weak var delegate: SongListVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }

    func setupUI() {
        view.backgroundColor = .white
        view.addSubview(tableview)
        tableview.frame = view.bounds
    }
    
    func commonInit() {
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableview.delegate = self
        tableview.dataSource = self
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let song = songs[indexPath.row]
        cell.textLabel?.text = song.name + " [ " + song.singer + " ] "
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.songListVCDidSelectedSong(song: songs[indexPath.row])
        dismiss(animated: true)
    }
}

extension SongListVC {
    struct Song {
        let name: String
        let singer: String
        let code: Int
        let highStartTime: Int
        let highEndTime: Int
    }
}

