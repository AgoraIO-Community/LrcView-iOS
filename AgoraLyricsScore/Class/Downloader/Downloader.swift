//
//  Downloader.swift
//  URLSessionDownloadDemo
//
//  Created by FancyLou on 2019/2/22.
//  Copyright © 2019 O2OA. All rights reserved.
//

import Foundation
import UIKit

typealias DownloadProgressClosure = ((_ progress:Float)->Void)
typealias DownloadCompletionClosure = ((_ filePath: String)->Void)
typealias DownloadFailClosure = ((_ error: DownloadError)-> Void)

class Downloader: NSObject {
    private var fail: DownloadFailClosure?
    private var completion: DownloadCompletionClosure?
    private var progress: DownloadProgressClosure?
    private var downloadUrl: URL?
    private var localUrl: URL?
    private var downloadSession: URLSession?
    private var fileOutputStream: OutputStream?
    private var downloadLoop: CFRunLoop?
    private var currentLength: Float = 0.0
    static var requestTimeoutInterval: TimeInterval = 60
    private let logTag = "Downloader"
  
    // 开始下载
    func download(url: URL, progress: @escaping DownloadProgressClosure, completion: @escaping DownloadCompletionClosure, fail: @escaping DownloadFailClosure) {
        self.progress = progress
        self.completion = completion
        self.fail = fail
        self.downloadUrl = url
        
        guard self.downloadSession == nil else {
            Log.errorText(text: "已经开始下载。。。。", tag: logTag)
            return
        }
        DispatchQueue.global().async {
            var request = URLRequest(url: self.downloadUrl!)
            request.httpMethod = "GET"
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = Downloader.requestTimeoutInterval
            // session会话
            self.downloadSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            // 创建下载任务
            let downloadTask = self.downloadSession?.dataTask(with: request)
            // 开始下载
            downloadTask?.resume()
            // 当前运行循环
            self.downloadLoop = CFRunLoopGetCurrent()
            CFRunLoopRun()
        }
        
    }
    
    // 取消下载任务
    func cancel() {
        self.downloadSession?.invalidateAndCancel()
        self.downloadSession = nil
        self.fileOutputStream = nil
        // 结束下载的线程
        CFRunLoopStop(self.downloadLoop)
    }
    
    
}

extension Downloader: URLSessionDataDelegate {
    // 接收到服务器响应的时候调用该方法 completionHandler .allow 继续接收数据
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        Log.debug(text: "远程服务器开始响应...............", tag: logTag)
        //初始化本地文件地址
        // 远程文件名称
        let filename = dataTask.response?.suggestedFilename ?? "unKnownFileTitle.tmp"
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        localUrl = dir.appendingPathComponent(filename)
        Log.debug(text: "本地地址：\(self.localUrl?.absoluteString ?? "")", tag: logTag)
        self.fileOutputStream = OutputStream(url: self.localUrl!, append: true)
        self.fileOutputStream?.open()
        completionHandler(.allow)
        
    }
    
    //接收到数据 可能调用多次
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        Log.debug(text: "接收到数据...............", tag: logTag)
        _ = data.withUnsafeBytes {
            self.fileOutputStream?.write($0, maxLength: data.count)
        }
        currentLength += Float(data.count)
        // 这里有个问题 有些自己做的数据返回 header里面没有length 那就无法计算进度
        let totalLength = Float(dataTask.response?.expectedContentLength ?? -1)
        var p = currentLength / totalLength
        if totalLength<0 {
            p = 0.0
        }
        Log.info(text: "current: \(currentLength) , total:\(totalLength), progress:\(p)", tag: logTag)
        self.progress?(p)
    }
    //下载结束 error有值表示失败
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Log.info(text: "下载完成...........urlSession", tag: logTag)
        self.fileOutputStream?.close()
        self.cancel()
        if error != nil {
            let e = DownloadError(codeType: .httpDownloadError, msg: error!.localizedDescription)
            self.fail?(e)
        }else {
            self.completion?(self.localUrl?.path ?? "")
        }
    }
}
