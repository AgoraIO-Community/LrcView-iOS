//
//  LyricsFileDownloader.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/12/13.
//

import Foundation
import Zip

public class LyricsFileDownloader: NSObject {
    typealias RequestId = Int
    
    /// max number of file in local (if reach max, sdk will remove oldest file)
    @objc public var maxFileNum: UInt8 = 50 { didSet { fileCache.maxFileNum = maxFileNum } }
    /// age of file (seconds), default is 8 hours
    @objc public var maxFileAge: UInt = 8 * 60 * 60 { didSet { fileCache.maxFileAge = maxFileAge } }
    @objc public weak var delegate: LyricsFileDownloaderDelegate?
    @objc public var delegateQueue = DispatchQueue.main
    private let fileCache = FileCache()
    private let downloaderManager = DownloaderManager()
    private let queue = DispatchQueue(label: "com.agora.LyricsFileDownloader.queue")
    private var requestIdDict = [RequestId : String]()
    private var currentRequestId: RequestId = 0
    private let maxConcurrentRequestCount = 3
    private var waittingTaskQueue = Queue<TaskInfo>()
    private let logTag = "LyricsFileDownloader"
    // MARK: - Public Method
    
    public override init() {
        Log.info(text: "init", tag: logTag)
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    /// start a download
    /// - Parameters:
    ///   - urlString: url from result of `AgoraMusicContentCenter`
    /// - Returns: `requestId`, if rseult < 0, means fail. if rseult >= 0, means success
    @objc public func download(urlString: String) -> Int {
        let requestId = genId()
        
        /** check file Exist **/
        if let fileData = fetchFromLocal(urlString: urlString) {
            queue.async { [weak self] in
                guard let self = self else {
                    return
                }
                invokeOnLyricsFileDownloadCompleted(requestId: requestId,
                                                    fileData: fileData,
                                                    error: nil)
            }
            return requestId
        }
        
        /** start download **/
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            /** check local file **/
            fileCache.removeFilesIfNeeded()
            
            if requestIdDict.count >= maxConcurrentRequestCount {
                let logText = "request(\(requestId) was enqueued in waittingTaskQueue, current num of requesting task is \(requestIdDict.count)"
                Log.info(text: logText, tag: logTag)
                let taskInfo = TaskInfo(requestId: requestId, urlString: urlString)
                waittingTaskQueue.enqueue(taskInfo)
            }
            else {
                _addRequest(id: requestId, urlString: urlString)
                _startDownload(requestId: requestId, urlString: urlString)
            }
        }
        
        return requestId
    }
    
    /// cancle a downloading task
    @objc public func cancleDownload(requestId: Int) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            _cancleDownload(requestId: requestId)
        }
    }
    
    /// clean all files in local
    @objc public func cleanAll() {
        _cleanAll()
    }
    
    // MARK: - Private Method - 0
    func fetchFromLocal(urlString: String) -> Data? {
        /** check if Exist **/
        let fileName = urlString.fileName.components(separatedBy: ".").first ?? ""
        if let xmlPath = FileCache.cacheFileExists(with: fileName + ".xml") {
            let url = URL(fileURLWithPath: xmlPath)
            let data = try? Data(contentsOf: url)
            return data
        }
        return nil
    }
    
    func _startDownload(requestId: Int, urlString: String) {
        Log.debug(text: "_startDownload requestId:\(requestId)", tag: logTag)
        guard let url = URL(string: urlString) else {
            _removeRequest(id: requestId)
            _resumeTaskIfNeeded()
            return
        }
        downloaderManager.download(url: url) { [weak self](progress) in
            guard let self = self else {
                return
            }
            invokeOnLyricsFileDownloadProgress(requestId: requestId, progress: progress)
        } completion: { [weak self](filePath) in
            guard let self = self else {
                return
            }
            if filePath.split(separator: ".").last == "lrc" { /** lrc type **/
                let url = URL(fileURLWithPath: filePath)
                do {
                    let data = try Data(contentsOf: url)
                    removeRequest(id: requestId)
                    resumeTaskIfNeeded()
                    invokeOnLyricsFileDownloadCompleted(requestId: requestId,
                                                        fileData: data,
                                                        error: nil)
                } catch let error {
                    let logText = "get data from [\(url)] failed: \(error.localizedDescription)"
                    Log.errorText(text: logText, tag: logTag)
                }
                return
            }
            
            /** xml type **/
            unzip(filePath: filePath, requestId: requestId)
        } fail: { [weak self](error) in
            guard let self = self else {
                return
            }
            removeRequest(id: requestId)
            resumeTaskIfNeeded()
            invokeOnLyricsFileDownloadCompleted(requestId: requestId, fileData: nil, error: error)
        }
    }
    
    func _cancleDownload(requestId: Int) {
        if let urlString = requestIdDict[requestId] {
            guard let url = URL(string: urlString) else {
                Log.errorText(text: "\(urlString) is not valid url", tag: logTag)
                return
            }
            downloaderManager.cancelTask(url: url)
        }
        else {
            _removeWaittingTaskIfNeeded(requestId: requestId)
        }
    }
    
    func _cleanAll() {
        fileCache.clearAll()
    }
    
    // MARK: - Private Method
    
    private func unzip(filePath: String, requestId: Int) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            _unzip(filePath: filePath, requestId: requestId)
        }
    }
    
    private func _unzip(filePath: String, requestId: Int) {
        let fileName = filePath.fileName.components(separatedBy: ".").first ?? ""
        let zipFile = URL(fileURLWithPath: filePath)
        let destination = URL(fileURLWithPath: .cacheFolderPath())
        do {
            try Zip.unzipFile(zipFile, destination: destination, overwrite: true, password: nil)
            let path = destination.path + "/" + fileName + ".xml"
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            removeRequest(id: requestId)
            resumeTaskIfNeeded()
            invokeOnLyricsFileDownloadCompleted(requestId: requestId,
                                                fileData: data,
                                                error: nil)
        } catch let error {
            removeRequest(id: requestId)
            resumeTaskIfNeeded()
            let e = DownloadError(domainType: .unzipFail,
                                  code: DownloadErrorDomainType.unzipFail.rawValue,
                                  msg: error.localizedDescription)
            invokeOnLyricsFileDownloadCompleted(requestId: requestId,
                                                fileData: nil,
                                                error: e)
        }
    }
    
    private func genId() -> RequestId {
        let id = currentRequestId
        currentRequestId = currentRequestId == Int.max ? 0 : currentRequestId + 1
        return id
    }
    
    private func addRequest(id: RequestId, urlString: String) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            _addRequest(id: id, urlString: urlString)
        }
    }
    
    private func removeRequest(id: RequestId) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            _removeRequest(id: id)
        }
    }
    
    private func _addRequest(id: RequestId, urlString: String) {
        requestIdDict[id] = urlString
    }
    
    private func _removeRequest(id: RequestId) {
        requestIdDict.removeValue(forKey: id)
    }
    
    private func resumeTaskIfNeeded() {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            _resumeTaskIfNeeded()
        }
    }
    
    private func _resumeTaskIfNeeded() {
        Log.debug(text: "_resumeTaskIfNeeded", tag: logTag)
        if requestIdDict.count >= maxConcurrentRequestCount {
            return
        }
        
        if let taskInfo = waittingTaskQueue.dequeue() {
            Log.info(text: "task was resume, requestId: \(taskInfo.requestId)", tag: logTag)
            _addRequest(id: taskInfo.requestId, urlString: taskInfo.urlString)
            _startDownload(requestId: taskInfo.requestId, urlString: taskInfo.urlString)
        }
    }
    
    private func _removeWaittingTaskIfNeeded(requestId: Int) {
        Log.debug(text: "_removeWaittingTaskIfNeeded \(requestId)", tag: logTag)
        var tasks = waittingTaskQueue.getAll()
        let contain = tasks.contains(where: { $0.requestId == requestId })
        if contain {
            tasks = tasks.filter({ requestId != $0.requestId })
            waittingTaskQueue.reset(newElements: tasks)
            Log.debug(text: "task (id:\(requestId)) was remove in waitting tasks ", tag: logTag)
        }
        else {
            Log.debug(text: "no task (id:\(requestId)) was should be remove in waitting tasks", tag: logTag)
        }
    }
}

// MARK: - Invoke

extension LyricsFileDownloader {
    fileprivate func invokeOnLyricsFileDownloadCompleted(requestId: Int,
                                                         fileData: Data?,
                                                         error: DownloadError?) {
        if Thread.isMainThread {
            delegate?.onLyricsFileDownloadCompleted(requestId: requestId,
                                                    fileData: fileData,
                                                    error: error)
            return
        }
        
        delegateQueue.async { [weak self] in
            self?.delegate?.onLyricsFileDownloadCompleted(requestId: requestId,
                                                          fileData: fileData,
                                                          error: error)
        }
    }
    
    fileprivate func invokeOnLyricsFileDownloadProgress(requestId: Int, progress: Float) {
        if Thread.isMainThread {
            delegate?.onLyricsFileDownloadProgress(requestId: requestId, progress: progress)
            return
        }
        delegateQueue.async { [weak self] in
            self?.delegate?.onLyricsFileDownloadProgress(requestId: requestId, progress: progress)
        }
    }
}
