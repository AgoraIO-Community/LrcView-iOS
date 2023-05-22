//
//  DownloaderManager.swift
//  URLSessionDownloadDemo
//
//  Created by FancyLou on 2019/2/22.
//  Copyright © 2019 O2OA. All rights reserved.
//

import Foundation


class DownloaderManager: NSObject {
    
    static let shared: DownloaderManager = DownloaderManager()
    
    // 下载缓存池
    private var downloadCache: Dictionary<String, Downloader>
    private var failback: DownloadFailClosure?
    
    private override init() {
        downloadCache = Dictionary()
    }
    
    func download(url: URL,
                  progress: @escaping DownloadProgressClosure,
                  completion: @escaping DownloadCompletionClosure,
                  fail: @escaping DownloadFailClosure)  {
        self.failback = fail
        // 判断缓存池中是否已经存在
        var downloader = self.downloadCache[url.path]
        if downloader != nil {
            print("当前下载已存在不需要重复下载！")
            self.failback?("当前下载已存在不需要重复下载！")
            return
        }
        downloader = Downloader()
        self.downloadCache[url.path] = downloader
        weak var managerWeak = self
        downloader?.download(url: url, progress: progress, completion: { (filePath) in
            completion(filePath)
            managerWeak?.downloadCache.removeValue(forKey: url.path)
        }, fail: fail)
    }
    
    func cancelTask(url: URL) {
        let downloader = self.downloadCache[url.path]
        if downloader == nil {
            self.failback?("任务已经移除，不需要重复移除！")
            return
        }
        //结束任务
        downloader?.cancel()
        // 从缓存池中删除
        self.downloadCache.removeValue(forKey: url.path)
    }
}
