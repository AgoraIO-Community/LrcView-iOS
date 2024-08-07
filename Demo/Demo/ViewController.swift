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
        title = "AgoraLyricsScore"
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
        list = [Section(title: "集成", rows: [.init(title: "内置打分"),
                                            .init(title: "外置打分（Ex）")]),
                Section(title: "体验", rows: [.init(title: "观众端"),
                                            .init(title: "主播端"),
                                            .init(title: "抢唱"),
                                            .init(title: "miniSize")]),
                Section(title: "模块", rows: [.init(title: "FirstToneHintView"),
                                            .init(title: "纯音乐"),
                                            .init(title: "歌词显示 mcc"),
                                            .init(title: "用AVPlayer测试"),
                                            .init(title: "Emitter测试"),
                                            .init(title: "得分动画测试"),
                                            .init(title: "激励动画测试"),
                                            .init(title: "LyricLabel测试"),
                                            .init(title: "OC"),
                                            .init(title: "profile"),
                                            .init(title: "下载")]),
                Section(title: "验证", rows: [.init(title: "krc查看")])]
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

        if indexPath.section == 0 { /** 集成测试 **/
            if indexPath.row == 0 {
                let vc = MainTestVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            if indexPath.row == 1 {
                let vc = MainTestVCEx()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            
        }
        
        if indexPath.section == 1 { /** 场景测试 **/
            if indexPath.row == 0 { /** 观众端 **/
                let vc = AudienceVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if indexPath.row == 1 { /** 主播端 **/
                let vc = HostVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if indexPath.row == 2 { /** 抢唱 **/
                let vc = QiangChangVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if indexPath.row == 3 { /** mini size 小视图 **/
                let vc = MiniSizeVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
        }

        if indexPath.section == 2 { /** 模块测试 **/
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

            if indexPath.row == 4 { /** Emitter测试 **/
                let vc = EmitterVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }

            if indexPath.row == 5 { /** 得分动画测试 **/
                let vc = ScoreAniVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }

            if indexPath.row == 6 { /** 激励动画测试 **/
                let vc = IncentiveVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }

            if indexPath.row == 7 { /** LyricLabel测试 **/
                let vc = LyricLabelVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }

            if indexPath.row == 8 { /** oc测试 **/
                let vc = OCVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if indexPath.row == 9 { /** Profile **/
                let vc = ProfileVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if indexPath.row == 10 { /** 下载 **/
                let vc = DownloadVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
        }
        
        if indexPath.section == 3 {
            if indexPath.row == 0 {
                let vc = SelectedLyricVC()
                navigationController?.pushViewController(vc, animated: true)
                return
            }
        }
    }
}
