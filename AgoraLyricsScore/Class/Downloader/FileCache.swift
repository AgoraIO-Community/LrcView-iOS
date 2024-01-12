//
//  FileCache.swift
//  Demo
//
//  Created by ZYP on 2023/2/7.
//

import Foundation
import Zip
class FileCache {
    /// 指定一个本地存储的文件数量最大值，当前保存的文件达到该数量时，内部会自动清理旧文件(淘汰最早的记录)。
    var maxFileNum: UInt8 = 50 { didSet { removeFilesIfNeeded() } }
    /// 文件的存活时间 单位:s
    var maxFileAge: UInt = 8 * 60 * 60 { didSet { removeFilesIfNeeded() } }
    private let logTag = "FileCache"
    
    init() {
        Log.info(text: "init", tag: logTag)
        let cacheFolderPathUrl = NSURL(fileURLWithPath: String.cacheFolderPath())
        FileManager.createDirectoryIfNeeded(atPath: cacheFolderPathUrl.path!)
    }
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
    }
    
    func removeFilesIfNeeded() {
        let files = findFiles(inDirectory: String.cacheFolderPath())
        let manager = FileManager.default
        var hasFileBeRemove = false
        var fileForMinCreationTime: ExistedFile?
        let currentTime = Date().timeIntervalSince1970
        
        for file in files { /** remove out date one **/
            let gap = UInt(currentTime - file.createdTimeStamp)
            let maxAge = UInt(maxFileAge)
            if gap > maxAge {
                do {
                    try manager.removeItem(atPath: file.path)
                    hasFileBeRemove = true
                    Log.debug(text: "did remove file: \(file.path)", tag: logTag)
                } catch let error {
                    Log.error(error: "removeFilesIfNeed error \(error.localizedDescription)", tag: logTag)
                }
            }
            else {
                if let currentFileForMinCreationTime = fileForMinCreationTime {
                    fileForMinCreationTime = currentFileForMinCreationTime.createdTimeStamp <= file.createdTimeStamp ? currentFileForMinCreationTime : file
                }
                else {
                    fileForMinCreationTime = file
                }
            }
        }
        
        /// remove earliest one
        if files.count >= maxFileNum,
           !hasFileBeRemove,
            let currentFileForMinCreationTime = fileForMinCreationTime {
            do {
                try manager.removeItem(atPath: currentFileForMinCreationTime.path)
                hasFileBeRemove = true
                Log.debug(text: "did remove file: \(currentFileForMinCreationTime.path)", tag: logTag)
            } catch let error {
                Log.error(error: "removeFilesIfNeed 2 error \(error.localizedDescription)", tag: logTag)
            }
        }
    }
      
    func findFiles(inDirectory directoryPath: String) -> [ExistedFile] {
        let fileManager = FileManager.default
        guard let directoryURL = URL(string: directoryPath) else {
            return []
        }
        var files: [ExistedFile] = []
        do {
            let directoryContents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
            for item in directoryContents {
                if let creationDate = try item.resourceValues(forKeys: [.creationDateKey]).creationDate {
                    let file = ExistedFile(path: item.path, createdTimeStamp: creationDate.timeIntervalSince1970)
                    files.append(file)
                }
            }
        } catch {
            Log.error(error: "findXMLandLRCFiles: \(error)", tag: logTag)
        }
        return files
    }
    
    func clearAll() {
        Log.debug(text: "clearAll start", tag: logTag)
        let fileManager = FileManager.default
        let files = findFiles(inDirectory: String.cacheFolderPath())
        if files.isEmpty {
            Log.debug(text: "no need to clear", tag: logTag)
            return
        }
        do {
            for file in files {
                try fileManager.removeItem(atPath: file.path)
                Log.debug(text: "rm \(file.path.fileName)", tag: logTag)
            }
        } catch let error {
            Log.error(error: "clearAll: \(error)", tag: logTag)
        }
        Log.debug(text: "clearAll end", tag: logTag)
    }
}

extension FileCache {
    /**
     *  是否存在缓存文件 存在：返回文件路径 不存在：返回nil
     */
    static func cacheFileExists(with url: String) -> String? {
        let cacheFilePath = "\(String.cacheFolderPath())/\(url.fileName)"
        if FileManager.default.fileExists(atPath: cacheFilePath) {
            return cacheFilePath
        }
        return nil
    }
    
    /**
     *  清空缓存文件
     */
    static func clearCache() -> Bool? {
        let manager = FileManager.default
        
        if let _ = try? manager.removeItem(atPath: String.cacheFolderPath()) {
            return true
        }
        return false
    }
    
    struct ExistedFile {
        let path: String
        let createdTimeStamp: Double
    }
}
