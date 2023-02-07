//
//  FileCache.swift
//  Demo
//
//  Created by ZYP on 2023/2/7.
//

import Foundation
import Zip
class FileCache {
    static func fect(urlString: String,
                     progress: @escaping DownloadProgressClosure,
                     completion: @escaping DownloadCompletionClosure,
                     fail: @escaping DownloadFailClosure) {
        let fileName = urlString.fileName.components(separatedBy: ".").first ?? ""
        if let xmlPath = FileCache.cacheFileExists(with: fileName + ".xml") {
            DispatchQueue.main.async {
                completion(xmlPath)
            }
            return
        }
        let url = URL(string: urlString)!
        DownloaderManager.shared.download(url: url,
                                          progress: progress,
                                          completion: { path in
            FileCache.unzip(filePath: path,
                            completion: completion,
                            fail: fail)
        }, fail: fail)
    }
    
    static func unzip(filePath: String,
                      completion: @escaping DownloadCompletionClosure,
                      fail: @escaping DownloadFailClosure) {
        let fileName = filePath.fileName.components(separatedBy: ".").first ?? ""
        DispatchQueue.global().async {
            let zipFile = URL(fileURLWithPath: filePath)
            let destination = URL(fileURLWithPath: .cacheFolderPath())
            do {
                try Zip.unzipFile(zipFile, destination: destination, overwrite: true, password: nil)
                DispatchQueue.main.async {
                    completion(destination.path + "/" + fileName + ".xml")
                }
            } catch let err {
                DispatchQueue.main.async {
                    fail("unzip fail: \(err.localizedDescription)")
                }
            }
        }
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
}
