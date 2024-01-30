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
    private var logTag = "Downloader"
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        if (downloadLoop != nil) {
            CFRunLoopStop(downloadLoop)
        }
    }
    
    override init() {
        super.init()
        Log.info(text: "init", tag: logTag)
    }
  
    // 开始下载
    func download(url: URL, progress: @escaping DownloadProgressClosure, completion: @escaping DownloadCompletionClosure, fail: @escaping DownloadFailClosure) {
        logTag += "[\(url.lastPathComponent)]"
        self.progress = progress
        self.completion = completion
        self.fail = fail
        self.downloadUrl = url
        
        guard self.downloadSession == nil else {
            Log.errorText(text: "已经开始下载。。。。", tag: logTag)
            return
        }
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                return
            }
            var request = URLRequest(url: self.downloadUrl!)
            request.httpMethod = "GET"
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = Downloader.requestTimeoutInterval
            // session会话
            downloadSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            // 创建下载任务
            let downloadTask = self.downloadSession?.dataTask(with: request)
            // 开始下载
            downloadTask?.resume()
            // 当前运行循环
            downloadLoop = CFRunLoopGetCurrent()
            CFRunLoopRun()
        }
        
    }
    
    // 取消下载任务
    func cancel() {
        downloadSession?.invalidateAndCancel()
        downloadSession = nil
        fileOutputStream = nil
        // 结束下载的线程
        if (downloadLoop != nil) {
            CFRunLoopStop(downloadLoop)
        }
    }
    
    func resetEventCloure() {
        fail = nil
        completion = nil
        progress = nil
    }
}

extension Downloader: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        Log.debug(text: "remote server start respone...", tag: logTag)
        if let resp = response as? HTTPURLResponse, resp.statusCode != 200 {
            Log.errorText(text: resp.description, tag: logTag)
            let e = DownloadError(domainType: .httpDownloadErrorLogic, code: resp.statusCode, msg: "http error: \(resp.statusCode)")
            Log.errorText(text: e.description, tag: logTag)
            fail?(e)
            fail = nil
            completionHandler(.cancel)
            cancel()
            return
        }
        
        // file name of remote
        let filename = dataTask.response?.suggestedFilename ?? "unKnownFileTitle.tmp"
        let downloadFloderURL = NSURL(fileURLWithPath: String.downloadedFloderPath())
        FileManager.createDirectoryIfNeeded(atPath: downloadFloderURL.path!)
        localUrl = downloadFloderURL.appendingPathComponent(filename)
        Log.debug(text: "local path：\(self.localUrl?.path ?? "")", tag: logTag)
        fileOutputStream = OutputStream(url: self.localUrl!, append: true)
        fileOutputStream?.open()
        completionHandler(.allow)
    }
    
    /// didReceive
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        Log.debug(text: "didReceive...", tag: logTag)
        data.withUnsafeBytes { bufferPointer in
            guard let baseAddress = bufferPointer.baseAddress else { return }
            self.fileOutputStream?.write(baseAddress, maxLength: bufferPointer.count)
        }
        currentLength += Float(data.count)
        // 这里有个问题 有些自己做的数据返回 header里面没有length 那就无法计算进度
        let totalLength = Float(dataTask.response?.expectedContentLength ?? -1)
        var progress = currentLength / totalLength
        if totalLength<0 {
            progress = 0.0
        }
        Log.info(text: "current: \(currentLength) , total:\(totalLength), progress:\(progress)", tag: logTag)
        self.progress?(progress)
    }
    
    /// Complete
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        fileOutputStream?.close()
        cancel()
        if error != nil {
            Log.errorText(text: "download fail: \(error!.localizedDescription)", tag: logTag)
            let e = DownloadError(domainType: .httpDownloadError, error: error! as NSError)
            fail?(e)
            fail = nil
        } else {
            Log.info(text: "download success", tag: logTag)
            completion?(self.localUrl?.path ?? "")
            completion = nil
        }
    }
}
