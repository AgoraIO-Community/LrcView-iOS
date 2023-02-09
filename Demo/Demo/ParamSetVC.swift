//
//  ParamSetVC.swift
//  Demo
//
//  Created by ZYP on 2023/1/30.
//

import UIKit
import AgoraLyricsScore

protocol ParamSetVCDelegate: NSObjectProtocol {
    func didSetParam(param: Param, noLyric: Bool)
}

class ParamSetVC: UIViewController {
    let tableview = UITableView(frame: .zero, style: .grouped)
    let button = UIButton()
    let noLyricButton = UIButton()
    var list = [Section]()
    let param = Param.default
    weak var delegate: ParamSetVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        createData()
        setupUI()
        commonInit()
    }
    
    func createData() {
        list = [Section(title: "karaoke", rows: [.init(title: "backgroundImage"),
                                                 .init(title: "spacing"),
                                                 .init(title: "scoringEnabled"),
                                                 .init(title: "打分难易程度（越大越难）"),
                                                 .init(title: "打分分值补偿")]),
                Section(title: "Lyrics", rows: [.init(title: "隐藏等待开始圆点"),
                                                .init(title: "等待开始圆点颜色"),
                                                .init(title: "等待开始圆点大小"),
                                                .init(title: "等待开始圆点底部间距"),
                                                .init(title: "正常歌词背景色"),
                                                .init(title: "高亮的歌词颜色（未命中）"),
                                                .init(title: "高亮的歌词填充颜色 （命中）"),
                                                .init(title: "正常歌词文字大小"),
                                                .init(title: "高亮歌词文字大小"),
                                                .init(title: "歌词上下间距"),
                                                .init(title: "歌词最大宽度"),
                                                .init(title: "拖拽"),
                                                .init(title: "无歌词提示文案"),
                                                .init(title: "无歌词提示文字颜色"),
                                                .init(title: "无歌词提示文字大小")]),
                Section(title: "Scoring", rows: [.init(title: "评分视图高度"),
                                                 .init(title: "渲染视图到顶部的间距"),
                                                 .init(title: "游标的起始位置"),
                                                 .init(title: "音准线的高度"),
                                                 .init(title: "音准线的基准因子"),
                                                 .init(title: "音准线默认的背景色"),
                                                 .init(title: "音准线匹配后的背景色"),
                                                 .init(title: "是否隐藏粒子动画效果"),
                                                 .init(title: "使用图片创建粒子动画"),
                                                 .init(title: "打分容忍度 范围：0-1"),
                                                 .init(title: "showDebugView"),
                ]),
        ]
    }
    
    func setupUI() {
        button.setTitle("确 定", for: .normal)
        button.backgroundColor = .red
        noLyricButton.setTitle("确定(无歌词)", for: .normal)
        noLyricButton.backgroundColor = .red
        view.addSubview(tableview)
        view.addSubview(button)
        view.addSubview(noLyricButton)
        tableview.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        noLyricButton.translatesAutoresizingMaskIntoConstraints = false
        
        tableview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableview.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80).isActive = true
        
        button.topAnchor.constraint(equalTo: tableview.bottomAnchor, constant: 10).isActive = true
        button.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 45).isActive = true
        
        noLyricButton.topAnchor.constraint(equalTo: tableview.bottomAnchor, constant: 10).isActive = true
        noLyricButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 45 + 100).isActive = true
    }
    
    func commonInit() {
        button.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        noLyricButton.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.reloadData()
    }
    
    @objc func buttonTap(_ sender: UIButton) {
        if sender != noLyricButton {
            delegate?.didSetParam(param: param, noLyric: false)
            dismiss(animated: true)
            return
        }
        
        delegate?.didSetParam(param: param, noLyric: true)
        dismiss(animated: true)
    }
    
    func configCell(indexPath: IndexPath, cell: UITableViewCell) {
        if indexPath.section == 0 {
            if indexPath.row == 0 { /** karaokeView.backgroundImage **/
                cell.detailTextLabel?.text = param.karaoke.backgroundImage != nil ? "有" : "无"
            }
            
            if indexPath.row == 1 { /** karaokeView.spacing **/
                cell.detailTextLabel?.text = "\(param.karaoke.spacing)"
            }
            
            if indexPath.row == 2 { /** karaokeView.scoringEnabled **/
                cell.detailTextLabel?.text = "\(param.karaoke.scoringEnabled ? "true" : "false")"
            }
            
            if indexPath.row == 3 {
                cell.detailTextLabel?.text = "\(param.karaoke.scoreLevel)"
            }
            
            if indexPath.row == 4 { /** karaokeView.scoringEnabled **/
                cell.detailTextLabel?.text = "\(param.karaoke.scoreCompensationOffset)"
            }
        }
        
        if indexPath.section == 1 {
            if indexPath.row == 0 { /** lyrcis.waitingViewHidden **/
                cell.detailTextLabel?.text = "\(param.lyric.waitingViewHidden ? "true" : "false")"
            }
            if indexPath.row == 1 { /** lyrcis.FirstToneHintViewStyle.backgroundColor **/
                cell.backgroundColor = param.lyric.firstToneHintViewStyle.backgroundColor
            }
            if indexPath.row == 2 { /** lyrcis.FirstToneHintViewStyle.size **/
                cell.detailTextLabel?.text = "\(param.lyric.firstToneHintViewStyle.size)"
            }
            if indexPath.row == 3 { /** lyrcis.FirstToneHintViewStyle.bottomMargin **/
                cell.detailTextLabel?.text = "\(param.lyric.firstToneHintViewStyle.bottomMargin)"
            }
            if indexPath.row == 4 { /** lyrcis.textNormalColor **/
                cell.backgroundColor = param.lyric.textNormalColor
            }
            if indexPath.row == 5 { /** lyrcis.textSelectedColor **/
                cell.backgroundColor = param.lyric.textSelectedColor
            }
            if indexPath.row == 6 { /** lyrcis.textHighlightedColor **/
                cell.backgroundColor = param.lyric.textHighlightedColor
            }
            if indexPath.row == 7 { /** lyricsView.textNormalFontSize **/
                cell.detailTextLabel?.text = "字体"
                cell.detailTextLabel?.font = param.lyric.textNormalFontSize
            }
            if indexPath.row == 8 { /** lyricsView.textHighlightFontSize **/
                cell.detailTextLabel?.text = "字体"
                cell.detailTextLabel?.font = param.lyric.textHighlightFontSize
            }
            if indexPath.row == 9 { /** lyricsView.lyricLineSpacing **/
                cell.detailTextLabel?.text = "\(param.lyric.lyricLineSpacing)"
            }
            if indexPath.row == 10 { /** lyricsView.maxWidth **/
                cell.detailTextLabel?.text = "\(param.lyric.maxWidth)"
            }
            if indexPath.row == 11 { /** param.lyric.draggable **/
                cell.detailTextLabel?.text = param.lyric.draggable ? "true" : "false"
            }
            if indexPath.row == 12 {
                cell.detailTextLabel?.text = param.lyric.noLyricTipsText
            }
            if indexPath.row == 13 {
                cell.backgroundColor = param.lyric.noLyricTipsColor
            }
            if indexPath.row == 14 {
                cell.detailTextLabel?.text = "字体"
                cell.detailTextLabel?.font = param.lyric.noLyricTipsFont
            }
        }
        
        if indexPath.section == 2 {
            /// 评分视图高度
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = "\(param.scoring.viewHeight)"
            }
            /// 渲染视图到顶部的间距
            if indexPath.row == 1 {
                cell.detailTextLabel?.text = "\(param.scoring.topSpaces)"
            }
            /// 游标的起始位置
            if indexPath.row == 2 {
                cell.detailTextLabel?.text = "\(param.scoring.defaultPitchCursorX)"
            }
            /// 音准线的高度
            if indexPath.row == 3 {
                cell.detailTextLabel?.text = "\(param.scoring.standardPitchStickViewHeight)"
            }
            /// 音准线的基准因子
            if indexPath.row == 4 {
                cell.detailTextLabel?.text = "\(param.scoring.movingSpeedFactor)"
            }
            
            /// 音准线默认的背景色
            if indexPath.row == 5 {
                cell.backgroundColor = param.scoring.standardPitchStickViewColor
            }
            
            /// 音准线匹配后的背景色
            if indexPath.row == 6 {
                cell.backgroundColor = param.scoring.standardPitchStickViewHighlightColor
            }
            
            /// 是否隐藏粒子动画效果
            if indexPath.row == 7 {
                cell.detailTextLabel?.text =  "\(param.scoring.particleEffectHidden ? "true" : "false")"
            }
            
            /// 使用图片创建粒子动画
            if indexPath.row == 8 {
                cell.detailTextLabel?.text = param.scoring.emitterImages != nil ? "有" : "无"
            }
            
            /// 打分容忍度 范围：0-1
            if indexPath.row == 9 {
                cell.detailTextLabel?.text = "\(param.scoring.hitScoreThreshold)"
            }
            
            /// showDebugView
            if indexPath.row == 10 {
                cell.detailTextLabel?.text = "\(param.scoring.showDebugView)"
            }
        }
    }
    
    func update(indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 { /** karaokeView.backgroundImage **/
                param.karaoke.backgroundImage = param.karaoke.backgroundImage != nil ? nil : UIImage(named: "ktv_top_bgIcon")
            }
            
            if indexPath.row == 1 { /** karaokeView.spacing **/
                param.karaoke.spacing = genValue(current: param.karaoke.spacing, ops: [0, 50, 100, 200])
            }
            
            if indexPath.row == 2 { /** karaokeView.scoringEnabled **/
                param.karaoke.scoringEnabled = !param.karaoke.scoringEnabled
            }
            
            if indexPath.row == 3 {
                param.karaoke.scoreLevel = genValue(current: param.karaoke.scoreLevel, ops: [0, 10, 30, 50, 70, 100])
            }
            
            if indexPath.row == 4 { /** karaokeView.scoringEnabled **/
                param.karaoke.scoreCompensationOffset = genValue(current: param.karaoke.scoreCompensationOffset, ops: [-100, -70, -10, 0, 10, 70, 100])
            }
        }
        
        if indexPath.section == 1 {
            if indexPath.row == 0 { /** lyrcis.waitingViewHidden **/
                param.lyric.waitingViewHidden = !param.lyric.waitingViewHidden
            }
            if indexPath.row == 1 { /** lyrcis.FirstToneHintViewStyle.backgroundColor **/
                param.lyric.firstToneHintViewStyle.backgroundColor = .random
            }
            if indexPath.row == 2 { /** lyrcis.FirstToneHintViewStyle.size **/
                param.lyric.firstToneHintViewStyle.size = genValue(current: param.lyric.firstToneHintViewStyle.size, ops: [5, 10, 20, 30])
            }
            if indexPath.row == 3 { /** lyrcis.FirstToneHintViewStyle.bottomMargin **/
                param.lyric.firstToneHintViewStyle.bottomMargin = genValue(current: param.lyric.firstToneHintViewStyle.bottomMargin, ops: [0, 15, 30, 45])
                
            }
            if indexPath.row == 4 { /** lyrcis.textNormalColor **/
                param.lyric.textNormalColor = .random
            }
            if indexPath.row == 5 { /** lyrcis.textSelectedColor **/
                param.lyric.textSelectedColor = .random
            }
            if indexPath.row == 6 { /** lyrcis.textHighlightedColor **/
                param.lyric.textHighlightedColor = .random
            }
            if indexPath.row == 7 { /** lyricsView.textNormalFontSize **/
                param.lyric.textNormalFontSize = UIFont(name: "PingFangSC-Semibold", size: .random(in: 5...25))!
            }
            if indexPath.row == 8 { /** lyricsView.textHighlightFontSize **/
                param.lyric.textHighlightFontSize = UIFont(name: "PingFangSC-Semibold", size: .random(in: 5...25))!
            }
            if indexPath.row == 9 { /** lyricsView.lyricLineSpacing **/
                param.lyric.lyricLineSpacing = genValue(current: param.lyric.lyricLineSpacing, ops: [0, 5, 10, 15, 20])
            }
            if indexPath.row == 10 { /** lyricsView.maxWidth **/
                param.lyric.maxWidth = genValue(current: param.lyric.maxWidth, ops: [30, 100, 220, UIScreen.main.bounds.width-30])
            }
            if indexPath.row == 11 { /** param.lyric.draggable **/
                param.lyric.draggable = !param.lyric.draggable
            }
            if indexPath.row == 12 {
                param.lyric.noLyricTipsText = "\(Int.random(in: 0...100))"
            }
            if indexPath.row == 13 {
                param.lyric.noLyricTipsColor = .random
            }
            if indexPath.row == 14 {
                param.lyric.noLyricTipsFont = UIFont(name: "PingFangSC-Semibold", size: .random(in: 5...25))!
            }
        }
        
        if indexPath.section == 2 {
            /// 评分视图高度
            if indexPath.row == 0 {
                param.scoring.viewHeight = genValue(current: param.scoring.viewHeight, ops: [100, 120, 150, 180, 200])
//                param.scoring.topSpaces = param.scoring.viewHeight * 0.3
            }
            /// 渲染视图到顶部的间距
            if indexPath.row == 1 {
                param.scoring.topSpaces = genValue(current: param.scoring.topSpaces, ops: [0, 30, 80, 120, 180])
//                param.scoring.viewHeight = param.scoring.topSpaces * 3
            }
            /// 游标的起始位置
            if indexPath.row == 2 {
                param.scoring.defaultPitchCursorX = genValue(current: param.scoring.defaultPitchCursorX, ops: [30, 100, 120, 180, 220])
            }
            /// 音准线的高度
            if indexPath.row == 3 {
                param.scoring.standardPitchStickViewHeight = genValue(current: param.scoring.standardPitchStickViewHeight, ops: [3, 6, 12, 24])
                
            }
            /// 音准线的基准因子
            if indexPath.row == 4 {
                param.scoring.movingSpeedFactor = genValue(current: param.scoring.movingSpeedFactor, ops: [30, 60, 120, 240])
            }
            
            /// 音准线默认的背景色
            if indexPath.row == 5 {
                param.scoring.standardPitchStickViewColor = .random
            }
            
            /// 音准线匹配后的背景色
            if indexPath.row == 6 {
                param.scoring.standardPitchStickViewHighlightColor = .random
            }
            
            /// 是否隐藏粒子动画效果
            if indexPath.row == 7 {
                param.scoring.particleEffectHidden = !param.scoring.particleEffectHidden
            }
            
            /// 使用图片创建粒子动画
            if indexPath.row == 8 {
                if param.scoring.emitterImages == nil {
                    param.scoring.emitterImages = .init(repeating: UIImage(named: "t1")!, count: .random(in: 1...10))
                }
                else {
                    param.scoring.emitterImages = nil
                }
            }
            
            /// 打分容忍度 范围：0-1
            if indexPath.row == 9 {
                param.scoring.hitScoreThreshold = genValue(current: param.scoring.hitScoreThreshold, ops: [0, 0.2, 0.5, 0.7, 1])
            }
            
            /// showDebugView
            if indexPath.row == 10 {
                param.scoring.showDebugView = !param.scoring.showDebugView
            }
        }
    }
    
    func genValue<T>(current: T, ops: [T]) -> T where T : Comparable {
        if !ops.contains(current) {
            fatalError()
        }
        
        for (index, value) in ops.enumerated() {
            if current == value {
                if index + 1 >= ops.count {
                    return ops[0]
                }
                else {
                    return ops[index + 1]
                }
            }
        }
        
        fatalError("never call this")
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
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        let item = list[indexPath.section].rows[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = .disclosureIndicator
        cell.detailTextLabel?.text = ""
        cell.detailTextLabel?.font = .systemFont(ofSize: 16)
        cell.backgroundColor = .white
        configCell(indexPath: indexPath, cell: cell)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        update(indexPath: indexPath)
        tableView.reloadData()
    }
}

