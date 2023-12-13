//
//  LyricsFileDownloader.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/12/13.
//

import Foundation
import Zip

public class LyricsFileDownloader: NSObject {
    /// max number file in local (if reach max, sdk will remove oldest file)
    @objc public var maxFileNum: UInt8 = 50 { didSet { fileCache.maxFileNum = maxFileNum } }
    /// age of file (seconds), default is 8 hours
    @objc public var maxFileAge: UInt = 8 * 60 * 60 { didSet { fileCache.maxFileAge = maxFileAge } }
    @objc public weak var delegate: LyricsFileDownloaderDelegate?
    @objc public var delegateQueue = DispatchQueue.main
    private let fileCache = FileCache()
    private let downloaderManager = DownloaderManager()
    private let queue = DispatchQueue(label: "com.agora.LyricsFileDownloader.queue")
    private var requestIdDict = [Int : String]()
    private var currentRequestId: Int = 0
    private let logTag = "LyricsFileDownloader"
    // MARK: - Public Method
    
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
            invokeOnLyricsFileDownloadCompleted(requestId: requestId,
                                                fileData: fileData,
                                                error: nil)
            return requestId
        }
        
        /** check local file **/
        fileCache.removeFilesIfNeeded()
        
        /** start download **/
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            _addRequest(id: requestId, urlString: urlString)
            _startDownload(urlString: urlString, requestId: requestId)
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
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            _cleanAll()
        }
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
    
    func _startDownload(urlString: String, requestId: Int) {
        let url = URL(string: urlString)!
        downloaderManager.download(url: url) { [weak self](progress) in
            guard let self = self else {
                return
            }
            invokeOnLyricsFileDownloadProgress(requestId: requestId, progress: progress)
        } completion: { [weak self](filePath) in
            guard let self = self else {
                return
            }
            if filePath.split(separator: ".").last == "lrc" {
                let url = URL(fileURLWithPath: filePath)
                let data = try! Data(contentsOf: url)
                removeRequest(id: requestId)
                invokeOnLyricsFileDownloadCompleted(requestId: requestId,
                                                    fileData: data,
                                                    error: nil)
                return
            }
            unzip(filePath: filePath, requestId: requestId)
        } fail: { [weak self](error) in
            guard let self = self else {
                return
            }
            removeRequest(id: requestId)
            invokeOnLyricsFileDownloadCompleted(requestId: requestId, fileData: nil, error: error)
        }
    }
    
    func _cancleDownload(requestId: Int) {
        if let urlString = requestIdDict[requestId] {
            let url = URL(string: urlString)!
            downloaderManager.cancelTask(url: url)
        }
        else {
            Log.debug(text: "no need to remove id:\(requestId)")
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
            invokeOnLyricsFileDownloadCompleted(requestId: requestId,
                                                fileData: data,
                                                error: nil)
        } catch let error {
            removeRequest(id: requestId)
            let e = DownloadError(codeType: .unzipFail, msg: error.localizedDescription)
            invokeOnLyricsFileDownloadCompleted(requestId: requestId,
                                                fileData: nil,
                                                error: e)
        }
    }
    
    private func genId() -> Int {
        let id = currentRequestId
        currentRequestId = currentRequestId == Int.max ? 0 : currentRequestId + 1
        return id
    }
    
    private func addRequest(id: Int, urlString: String) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            _addRequest(id: id, urlString: urlString)
        }
    }
    
    private func removeRequest(id: Int) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            _removeRequest(id: id)
        }
    }
    
    private func _addRequest(id: Int, urlString: String) {
        requestIdDict[id] = urlString
    }
    
    private func _removeRequest(id: Int) {
        requestIdDict.removeValue(forKey: id)
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
