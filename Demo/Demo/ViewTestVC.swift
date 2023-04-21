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
    let tableview = UITableView(frame: .zero, style: .grouped)
    private var timer = GCDTimer()
    var list = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createData()
        setupUI()
        commonInit()
    }

    func createData() {
        list = [Section(title: "karaokeView", rows: [.init(title: "backgroundImage"),
                                                     .init(title: "spacing"),
                                                     .init(title: "scoringEnabled")]),
                Section(title: "LyricsView", rows: [.init(title: "隐藏等待开始圆点"),
                                                    .init(title: "正常歌词背景色"),
                                                    .init(title: "高亮的歌词颜色（未命中）"),
                                                    .init(title: "高亮的歌词填充颜色 （命中）"),
                                                    .init(title: "正常歌词文字大小"),
                                                    .init(title: "高亮歌词文字大小"),
                                                    .init(title: "歌词上下间距"),
                                                    .init(title: "歌词最大宽度"),]),
                Section(title: "ScoringView", rows: [.init(title: "评分视图高度"),
                                                     .init(title: "渲染视图到顶部的间距"),
                                                     .init(title: "游标的起始位置"),
                                                     .init(title: "音准线的高度"),
                                                     .init(title: "音准线的基准因子"),
                                                     .init(title: "音准线默认的背景色"),
                                                     .init(title: "音准线匹配后的背景色"),
                                                     .init(title: "showDebugView")
                ]),
        ]
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
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
        
        reset()
    }
    
    func reset() {
        karaokeView.reset()
        
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "745012", ofType: "xml")!)
        let data = try! Data(contentsOf: url)
        let model = KaraokeView.parseLyricData(data: data)!
        karaokeView.setLyricData(data: model)
        karaokeView.setProgress(progress: 70 * 1000)
    }
    
}

extension ViewTestVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return list[section].title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return list.count
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
        if indexPath.section == 1 {
            if indexPath.row == 0 { /** lyrcis.waitingViewHidden **/
                karaokeView.lyricsView.waitingViewHidden = !karaokeView.lyricsView.waitingViewHidden
                reset()
                return
            }
            if indexPath.row == 1 { /** lyrcis.textNormalColor **/
                karaokeView.lyricsView.inactiveLineTextColor = .green
                reset()
                return
            }
            if indexPath.row == 2 { /** lyrcis.textHighlightColor **/
                karaokeView.lyricsView.activeLineUpcomingTextColor = .red
                reset()
                return
            }
            if indexPath.row == 3 { /** lyrcis.textHighlightFillColor **/
                karaokeView.lyricsView.activeLinePlayedTextColor = .yellow
                reset()
                return
            }
            if indexPath.row == 4 { /** lyricsView.textNormalFontSize **/
                karaokeView.lyricsView.inactiveLineFontSize = .systemFont(ofSize: 20)
                reset()
                return
            }
            if indexPath.row == 5 { /** lyricsView.textHighlightFontSize **/
                karaokeView.lyricsView.activeLineUpcomingFontSize = .systemFont(ofSize: 23)
                reset()
                return
            }
            if indexPath.row == 6 { /** lyricsView.textHighlightFontSize **/
                karaokeView.lyricsView.lyricLineSpacing = CGFloat.random(in: 5...50)
                reset()
                return
            }
            if indexPath.row == 7 { /** lyricsView.maxWidth **/
                karaokeView.lyricsView.maxWidth = CGFloat.random(in: 100...350)
                reset()
                return
            }
        }
        
        if indexPath.section == 2 {
            /// 评分视图高度
            if indexPath.row == 0 {
                karaokeView.scoringView.viewHeight = CGFloat.random(in: 120...UIScreen.main.bounds.size.height * 2/3)
            }
            /// 渲染视图到顶部的间距
            if indexPath.row == 1 {
                karaokeView.scoringView.topSpaces = CGFloat.random(in: 0...UIScreen.main.bounds.size.height * 2/3)
            }
            /// 游标的起始位置
            if indexPath.row == 2 {
                karaokeView.scoringView.defaultPitchCursorX = CGFloat.random(in: 1...UIScreen.main.bounds.size.width)
            }
            /// 音准线的高度
            if indexPath.row == 3 {
                karaokeView.scoringView.standardPitchStickViewHeight = CGFloat.random(in: 1...120)
            }
            /// 音准线的基准因子
            if indexPath.row == 4 {
                karaokeView.scoringView.movingSpeedFactor = CGFloat.random(in: 1...400)
            }
            
            /// 音准线默认的背景色
            if indexPath.row == 5 {
                karaokeView.scoringView.standardPitchStickViewColor = .white
            }
            
            /// 音准线匹配后的背景色
            if indexPath.row == 6 {
                karaokeView.scoringView.standardPitchStickViewHighlightColor = .green
            }
            
            /// showDebugView
            if indexPath.row == 7 {
                karaokeView.scoringView.showDebugView = Bool.random()
            }
            
            reset()
        }
    }
}



