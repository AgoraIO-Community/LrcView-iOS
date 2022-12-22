//
//  ViewTestVC.swift
//  Demo
//
//  Created by ZYP on 2022/12/21.
//

import UIKit
import AgoraLyricsScore

class ViewTestVC: UIViewController {

    let karaokeView = KaraokeView()
    let tableview = UITableView()
    private var timer = GCDTimer()
    var list = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createData()
        setupUI()
        commonInit()
        

//        karaokeView.spacing = 0
//        karaokeView.scoringEnabled = false
    }

    func createData() {
        list = [Section(title: "karaokeView", rows: [.init(title: "backgroundImage"),
                                                     .init(title: "spacing"),
                                                     .init(title: "scoringEnabled")]),
                Section(title: "LyricsView", rows: [.init(title: "123"),
                                                    .init(title: "456")])
        ]
    }
    
    func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(karaokeView)
        view.addSubview(tableview)
        karaokeView.translatesAutoresizingMaskIntoConstraints = false
        tableview.translatesAutoresizingMaskIntoConstraints = false
        
        karaokeView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        karaokeView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        karaokeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        karaokeView.bottomAnchor.constraint(equalTo: tableview.topAnchor).isActive = true
        
        tableview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableview.heightAnchor.constraint(equalToConstant: 300).isActive = true
        tableview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func commonInit() {
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.reloadData()
    }
    
}

extension ViewTestVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = list[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 { /** karaokeView.backgroundImage **/
                karaokeView.backgroundImage = karaokeView.backgroundImage == nil ? UIImage(named: "ktv_top_bgIcon") : nil
                return
            }
            
            if indexPath.row == 1 { /** karaokeView.spacing **/
                karaokeView.spacing = CGFloat.random(in: 0...100)
                return
            }
            
            if indexPath.row == 2 { /** karaokeView.scoringEnabled **/
                karaokeView.scoringEnabled = !karaokeView.scoringEnabled
                return
            }
        }
        
    }
}



