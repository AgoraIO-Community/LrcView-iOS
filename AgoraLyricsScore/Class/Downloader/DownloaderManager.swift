//
//  DownloaderManager.swift
//  URLSessionDownloadDemo
//
//  Created by FancyLou on 2019/2/22.
//  Copyright © 2019 O2OA. All rights reserved.
//

import Foundation


class DownloaderManager: NSObject {
    // 下载缓存池
    private var downloadCache = SafeDictionary<String, Downloader>()
    private var failback: DownloadFailClosure?
    private let logTag = "DownloaderManager"
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        let downloadFloderURL = NSURL(fileURLWithPath: String.downloadedFloderPath())
        FileManager.createDirectoryIfNeeded(atPath: downloadFloderURL.path!)
    }
    
    override init() {
        Log.info(text: "init", tag: logTag)
    }
    
    func download(url: URL,
                  progress: @escaping DownloadProgressClosure,
                  completion: @escaping DownloadCompletionClosure,
                  fail: @escaping DownloadFailClosure)  {
        self.failback = fail
        // 判断缓存池中是否已经存在
        var downloader = downloadCache.getValue(forkey: url.absoluteString)
        if downloader != nil {
            Log.errorText(text: "当前下载已存在不需要重复下载！", tag: logTag)
            let e = DownloadError(domainType: .repeatDownloading,
                                  code: DownloadErrorDomainType.repeatDownloading.rawValue,
                                  msg: "当前下载已存在不需要重复下载")
            self.failback?(e)
            return
        }
        downloader = Downloader()
        downloadCache.set(value: downloader!, forkey: url.absoluteString)
        downloader?.download(url: url, progress: progress, completion: { [weak self](filePath) in
            guard let self = self else {
                return
            }
            downloadCache.removeValue(forkey: url.absoluteString)
            completion(filePath)
        }, fail: fail)
    }
    
    func cancelTask(url: URL) {
        let downloader = downloadCache.getValue(forkey: url.absoluteString)
        if downloader == nil {
            Log.debug(text: "任务已经移除，不需要重复移除！", tag: logTag)
            return
        }
        // 从缓存池中删除
        downloadCache.removeValue(forkey: url.absoluteString)
        //结束任务
        downloader?.resetEventCloure()
        downloader?.cancel()
    }
    
    
}
