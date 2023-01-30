//
//  ParamSetVC.swift
//  Demo
//
//  Created by ZYP on 2023/1/30.
//

import UIKit
import AgoraLyricsScore

protocol ParamSetVCDelegate: NSObjectProtocol {
    func didSetParam(param: Param)
}

class ParamSetVC: UIViewController {
    let tableview = UITableView(frame: .zero, style: .grouped)
    let button = UIButton()
    var list = [Section]()
    let param = Param()
    weak var delegate: ParamSetVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createData()
        setupUI()
        
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
        button.setTitle("确 定", for: .normal)
        button.backgroundColor = .red
        view.addSubview(tableview)
        view.addSubview(button)
        tableview.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        tableview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableview.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80).isActive = true
        
        button.topAnchor.constraint(equalTo: tableview.bottomAnchor, constant: 45).isActive = true
        button.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 45).isActive = true
    }
    
    func commonInit() {
        button.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.reloadData()
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        delegate?.didSetParam(param: param)
        dismiss(animated: true)
    }
}

extension ParamSetVC: UITableViewDelegate, UITableViewDataSource {
    
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
                return
            }
            
            if indexPath.row == 1 { /** karaokeView.spacing **/
                return
            }
            
            if indexPath.row == 2 { /** karaokeView.scoringEnabled **/
                return
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 { /** lyrcis.waitingViewHidden **/
                return
            }
            if indexPath.row == 1 { /** lyrcis.textNormalColor **/
                return
            }
            if indexPath.row == 2 { /** lyrcis.textHighlightColor **/
                return
            }
            if indexPath.row == 3 { /** lyrcis.textHighlightFillColor **/
                return
            }
            if indexPath.row == 4 { /** lyricsView.textNormalFontSize **/
                return
            }
            if indexPath.row == 5 { /** lyricsView.textHighlightFontSize **/
                return
            }
            if indexPath.row == 6 { /** lyricsView.textHighlightFontSize **/
                return
            }
            if indexPath.row == 7 { /** lyricsView.maxWidth **/
                return
            }
        }
        
        if indexPath.section == 2 {
            /// 评分视图高度
            if indexPath.row == 0 {
            }
            /// 渲染视图到顶部的间距
            if indexPath.row == 1 {
                
            }
            /// 游标的起始位置
            if indexPath.row == 2 {
                
            }
            /// 音准线的高度
            if indexPath.row == 3 {
                
            }
            /// 音准线的基准因子
            if indexPath.row == 4 {
                
            }
            
            /// 音准线默认的背景色
            if indexPath.row == 5 {
                
            }
            
            /// 音准线匹配后的背景色
            if indexPath.row == 6 {
                
            }
            
            /// showDebugView
            if indexPath.row == 7 {
                
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

class Param {
    let karaoke = KaraokeViewParam()
    let lyric = LyricViewParam()
    let scoring = ScoringViewParam()
}

class KaraokeViewParam {
    /// 背景图
    var backgroundImage: UIImage? = nil
    
    /// 是否使用评分功能
    /// - Note: 当`LyricModel.hasPitch = false`，强制不使用
    /// - Note: 当为 `false`, 会隐藏评分视图
    var scoringEnabled: Bool = true
    
    /// 评分组件和歌词组件之间的间距 默认: 0
    var spacing: CGFloat = 0
}

class LyricViewParam {
    /// 无歌词提示文案
    var noLyricTipsText: String = "无歌词"
    /// 无歌词提示文字颜色
    var noLyricTipsColor: UIColor = .orange
    /// 无歌词提示文字大小
    var noLyricTipsFont: UIFont = .systemFont(ofSize: 17)
    /// 是否隐藏等待开始圆点
    var waitingViewHidden: Bool = false
    /// 正常歌词颜色
    var textNormalColor: UIColor = .gray
    /// 选中的歌词颜色
    var textSelectedColor: UIColor = .white
    /// 高亮的歌词颜色 （命中）
    var textHighlightedColor: UIColor = .orange
    /// 正常歌词文字大小
    var textNormalFontSize = UIFont(name: "PingFangSC-Semibold", size: 15)!
    /// 高亮歌词文字大小
    var textHighlightFontSize = UIFont(name: "PingFangSC-Semibold", size: 18)!
    /// 歌词最大宽度
    var maxWidth: CGFloat = UIScreen.main.bounds.width - 30
    /// 歌词上下间距
    var lyricLineSpacing: CGFloat = 10
    /// 等待开始圆点风格
    var firstToneHintViewStyle: FirstToneHintViewStyle = .init()
    /// 是否开启拖拽
    var draggable: Bool = false
}

class ScoringViewParam {
    /// 评分视图高度
    var viewHeight: CGFloat = 120
    /// 渲染视图到顶部的间距
    var topSpaces: CGFloat = 0
    /// 游标的起始位置
    var defaultPitchCursorX: CGFloat = 100
    /// 音准线的高度
    var standardPitchStickViewHeight: CGFloat = 3
    /// 音准线的基准因子
    var movingSpeedFactor: CGFloat = 120
    /// 音准线默认的背景色
    var standardPitchStickViewColor: UIColor = .gray
    /// 音准线匹配后的背景色
    var standardPitchStickViewHighlightColor: UIColor = .orange
    /// 是否隐藏粒子动画效果
    var particleEffectHidden: Bool = false
    /// 使用图片创建粒子动画
    var emitterImages: [UIImage]?
    /// 打分容忍度 范围：0-1
    var hitScoreThreshold: Float = 0.7
    /// use for debug only
    var showDebugView = false
}
