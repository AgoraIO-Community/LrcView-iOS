//
//  ViewController.swift
//  Demo
//
//  Created by ZYP on 2022/12/21.
//

import UIKit

class ViewController: UIViewController {

    let tableview = UITableView(frame: .zero, style: .grouped)
    var list = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createData()
        setupUI()
        commonInit()
    }

    func setupUI() {
        view.addSubview(tableview)
        tableview.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    func createData() {
        list = [Section(title: "UI", rows: [.init(title: "View配置")]),
                Section(title: "体验", rows: [.init(title: "FirstToneHintView"),
                                            .init(title: "纯音乐"),
                                            .init(title: "歌词显示 mcc"),
                                            .init(title: "用AVPlayer测试")])]
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        list[section].title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        list.count
    }
    
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
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 { /** UI配置测试 **/
            let vc = ViewTestVC()
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        if indexPath.section == 1 {
            if indexPath.row == 0 { /** 等待视图 **/
                let vc = FirstToneHintViewTestVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if indexPath.row == 1 { /** 纯音乐 **/
                let vc = NoLyricsTestVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if indexPath.row == 2 { /** 歌词显示 **/
                let vc = LyricsTestVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if indexPath.row == 3 { /** 用AVPlayer测试 **/
                let vc = AVPlayerTestVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
        }
    }
}

struct Section {
    let title: String
    let rows: [Row]
}

struct Row {
    let title: String
}