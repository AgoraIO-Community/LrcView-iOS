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
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    var session: URLSession!
    private var task: URLSessionDownloadTask? // 任务
    
    override init() {
        super.init()
        session = URLSession(configuration: .default,
                             delegate: self,
                             delegateQueue: .current)
    }
    
    
    func download(urlString: String) {
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        task = session.downloadTask(with: request)
        task?.resume()
    }
}

extension SongDownloadManager: URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        delegate?.songDownloadManagerDidFinished(localUrl: location.absoluteURL)
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) * 1.0 / Double(totalBytesExpectedToWrite)
        print("\(progress)")
    }

    // 请求完成会调用该方法，请求失败则error有值
    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        if let e = error {
            print(e.localizedDescription)
        }
    }
}

