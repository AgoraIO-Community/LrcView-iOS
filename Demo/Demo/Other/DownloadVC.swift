//
//  DownloadVC.swift
//  Demo
//
//  Created by ZYP on 2023/12/14.
//

import UIKit
import AgoraLyricsScore

class DownloadVC: UIViewController {
    let downloadView = DownloadView()
    let lyricsFileDownloader = LyricsFileDownloader()
    var currentUrlIndex = 0
    let urlStrings = ["https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/1.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/2.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/3.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/4.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/5.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/6.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/7.zip",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/8.lrc",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/9.lrc",
                      "https://fullapp.oss-cn-beijing.aliyuncs.com/lyricsMockDownload/10.lrc"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(downloadView)
        downloadView.frame = view.bounds
        downloadView.delegate = self
        
        /// init internal log
        let _ = KaraokeView.init(frame: .zero, loggers: [ConsoleLogger(), FileLogger()])
        
        lyricsFileDownloader.delegate = self
    }
}

extension DownloadVC: DownloadViewDelegate, LyricsFileDownloaderDelegate {
    func downloadViewDidTapAction(action: DownloadView.Action, info: DownloadView.Info?) {
        if action == .addOne {
            let urlString = urlStrings[currentUrlIndex]
            let requesetId = lyricsFileDownloader.download(urlString: urlString)
            let item = DownloadView.Info(requestId: requesetId, urlString: urlString)
            downloadView.addInfos(infos: [item])
            currentUrlIndex = currentUrlIndex == urlStrings.count - 1 ? 0 : currentUrlIndex + 1
            return
        }
        
        if action == .addAll {
            for urlString in urlStrings {
                let requesetId = lyricsFileDownloader.download(urlString: urlString)
                let item = DownloadView.Info(requestId: requesetId, urlString: urlString)
                downloadView.addInfos(infos: [item])
            }
            return
        }
        
        if action == .clear {
            lyricsFileDownloader.cleanAll()
            return
        }
        
        if action == .cancel, let info = info {
            if info.state == .created || info.state == .progress {
                lyricsFileDownloader.cancelDownload(requestId: info.requestId)
                info.state = .canceled
                downloadView.reloadData()
            }
        }
    }
    
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        print("progress:\(progress)")
        if let item = downloadView.getInfo(requestId: requestId) {
            item.state = .progress
            item.progress = progress
            downloadView.reloadData()
        }
    }
    
    func onLyricsFileDownloadCompleted(requestId: Int,
                                       fileData: Data?,
                                       error: AgoraLyricsScore.DownloadError?) {
        if let item = downloadView.getInfo(requestId: requestId) {
            item.state = fileData == nil ? .doneFail : .doneSuccess
            downloadView.reloadData()
        }
    }
}
