//
//  SongDownloadManager.swift
//  AgoraKaraokeScore
//
//  Created by ZYP on 2022/10/13.
//

import UIKit

protocol SongDownloadManagerDelegate: NSObjectProtocol {
    func songDownloadManagerDidFinished(localUrl: URL)
}

class SongDownloadManager: NSObject {
    weak var delegate: SongDownloadManagerDelegate?
    
    func download(urlString: String) {
        AgoraDownLoadManager.manager.downloadMP3(urlString: urlString) { [weak self](path) in
            let url = URL(fileURLWithPath: path ?? "")
            self?.delegate?.songDownloadManagerDidFinished(localUrl: url)
        }
    }
}
