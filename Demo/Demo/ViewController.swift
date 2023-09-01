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
        list = [Section(title: "体验", rows: [.init(title: "抢唱")])]
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
        let vc = QiangChangScoringVC()
        navigationController?.pushViewController(vc, animated: true)
    }
}
