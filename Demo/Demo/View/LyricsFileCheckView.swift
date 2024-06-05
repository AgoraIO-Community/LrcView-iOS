//
//  LyricsFileCheckView.swift
//  Demo
//
//  Created by ZYP on 2024/5/21.
//

import UIKit
import AgoraLyricsScore

protocol LyricsFileCheckViewDelegate: NSObjectProtocol {
    func lyricsFileCheckView(_ view: LyricsFileCheckView, didSelectRowAt index: Int)
    func lyricsFileCheckView(_ view: LyricsFileCheckView, didScrollAt point: CGPoint)
}

class LyricsFileCheckView: UIView {
    /// 游标的起始位置
    var defaultPitchCursorX: CGFloat = 100
    private let scrollView = UIScrollView()
    private let defaultPitchCursorLineView = UIView()
    private let progressLabel = UILabel()
    private let tableView = UITableView()
    var dataList = [Info]()
    weak var delegate: LyricsFileCheckViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        scrollView.backgroundColor = .white
        defaultPitchCursorLineView.backgroundColor = .black
        progressLabel.textColor = .gray
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = UIColor.gray.cgColor
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.gray.cgColor
        addSubview(scrollView)
        addSubview(defaultPitchCursorLineView)
        addSubview(tableView)
        addSubview(progressLabel)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        defaultPitchCursorLineView.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 200)
        ])
        NSLayoutConstraint.activate([
            defaultPitchCursorLineView.topAnchor.constraint(equalTo: topAnchor),
            defaultPitchCursorLineView.widthAnchor.constraint(equalToConstant: 1),
            defaultPitchCursorLineView.leftAnchor.constraint(equalTo: leftAnchor, constant: defaultPitchCursorX),
            defaultPitchCursorLineView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
        NSLayoutConstraint.activate([
            progressLabel.centerXAnchor.constraint(equalTo: defaultPitchCursorLineView.centerXAnchor),
            progressLabel.topAnchor.constraint(equalTo: defaultPitchCursorLineView.bottomAnchor)
        ])
        NSLayoutConstraint.activate([
            tableView.heightAnchor.constraint(equalToConstant: 200),
            tableView.rightAnchor.constraint(equalTo: rightAnchor),
            tableView.leftAnchor.constraint(equalTo: leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func commonInit() {
        tableView.delegate = self
        tableView.dataSource = self
        scrollView.delegate = self
    }
    
    func setDrawInfo(pitchDrawInfos: [PitchDrawInfo], lyricLineDrawInfos: [LyricLineDrawInfo]) {
        let width = max(pitchDrawInfos.map({ $0.rect.maxX }).max()!, lyricLineDrawInfos.map({ $0.rect.maxX }).max()!)
        scrollView.contentSize = CGSize(width: width, height: scrollView.bounds.height)

        /// 按照pitchDrawInfos.rect增加view到scrollView
        pitchDrawInfos.enumerated().forEach { (offset, pitchDrawInfo) in
            let pitchLabel = UILabel(frame: pitchDrawInfo.rect)
            pitchLabel.backgroundColor = .red
            pitchLabel.text = "[\(offset)]"
            pitchLabel.layer.borderWidth = 1
            pitchLabel.layer.borderColor = UIColor.gray.cgColor
            scrollView.addSubview(pitchLabel)
        }

        /// 按照lyricLineDrawInfos.rect增加view到scrollView
        lyricLineDrawInfos.enumerated().forEach { (offset, lyricLineDrawInfo) in
            let lyricLineLabel = UILabel(frame: lyricLineDrawInfo.rect)
            lyricLineLabel.text = "[\(offset)]" + lyricLineDrawInfo.content
            lyricLineLabel.textColor = .white
            lyricLineLabel.backgroundColor = .blue
            lyricLineLabel.layer.borderWidth = 1
            lyricLineLabel.layer.borderColor = UIColor.gray.cgColor
            scrollView.addSubview(lyricLineLabel)
            
            lyricLineDrawInfo.toneDrawInfos.enumerated().forEach { (toneOffset, toneDrawInfo) in
                let toneLabel = UILabel(frame: toneDrawInfo.rect)
                toneLabel.text = toneDrawInfo.toneInfo.word
                toneLabel.textColor = .white
                toneLabel.backgroundColor = .green
                toneLabel.layer.borderWidth = 1
                toneLabel.layer.borderColor = UIColor.gray.cgColor
                scrollView.addSubview(toneLabel)
            }
        }
        
        dataList = lyricLineDrawInfos.map({ Info(title: $0.content, begin: $0.lineInfo.beginTime, end: $0.lineInfo.duration + $0.lineInfo.beginTime) })
        tableView.reloadData()
    }
    
    func seek(point: CGPoint) {
        scrollView.setContentOffset(point, animated: true)
    }
    
    func showProgress(progress: UInt) {
        progressLabel.text = "\(progress)"
    }
}

extension LyricsFileCheckView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let info = dataList[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = "[\(indexPath.row)]:\(info.title)"
        cell.detailTextLabel?.text = "[\(info.begin), \(info.end)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.lyricsFileCheckView(self, didSelectRowAt: indexPath.row)
    }
}

extension LyricsFileCheckView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.lyricsFileCheckView(self, didScrollAt: scrollView.contentOffset)
    }
}

extension LyricsFileCheckView {
    typealias PitchInfo = CheckLyricVC.PitchInfo
    
    struct PitchDrawInfo {
        let rect: CGRect
        let pitchInfo: PitchInfo
    }
    
    struct LyricLineDrawInfo {
        let rect: CGRect
        let toneDrawInfos: [LyricToneDrawInfo]
        let lineInfo: LyricLineModel
        let content: String
        init(rect: CGRect, toneDrawInfos: [LyricToneDrawInfo], lineInfo: LyricLineModel) {
            self.rect = rect
            self.lineInfo = lineInfo
            self.toneDrawInfos = toneDrawInfos
            self.content = toneDrawInfos.map({ $0.toneInfo.word }).joined()
        }
    }
    
    struct LyricToneDrawInfo {
        let rect: CGRect
        let toneInfo: LyricToneModel
    }
    
    struct Info {
        let title: String
        let begin: UInt
        let end: UInt
    }
}
