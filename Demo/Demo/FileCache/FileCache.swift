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
                     reqType: Int,
                     progress: @escaping DownloadProgressClosure,
                     completion: @escaping DownloadCompletionClosure2,
                     fail: @escaping DownloadFailClosure) {
        createLyricsIfNeeded()
        
        let fileName = urlString.fileName.components(separatedBy: ".").first ?? ""
        if reqType == 0, let xmlPath = FileCache.cacheFileExists(with: fileName + ".xml") {
            DispatchQueue.main.async {
                completion(xmlPath, nil)
            }
            return
        }
        if reqType == 1, let lrcPath = FileCache.cacheFileExists(with: fileName + ".lrc") {
            DispatchQueue.main.async {
                completion(lrcPath, nil)
            }
            return
        }
        if reqType == 3, let xmlPath = FileCache.cacheFileExists(with: fileName + ".xml") {
            let pitchPath = FileCache.cacheFileExists(with: fileName + ".pitch")
            DispatchQueue.main.async {
                completion(xmlPath, pitchPath)
            }
            return
        }
        if reqType == 4, let lrcPath = FileCache.cacheFileExists(with: fileName + ".lrc") {
            let pitchPath = FileCache.cacheFileExists(with: fileName + ".pitch")
            DispatchQueue.main.async {
                completion(lrcPath, pitchPath)
            }
            return
        }
        
        let url = URL(string: urlString)!
        DownloaderManager.shared.download(url: url,
                                          progress: progress,
                                          completion: { path in
            if path.split(separator: ".").last == "lrc" {
                let destination = String.cacheFolderPath() + "/\(fileName)" + ".lrc"
                do {
                    
                    let isFolderExist = FileManager.default.fileExists(atPath: String.cacheFolderPath())
                    if !isFolderExist {
                        try FileManager.default.createDirectory(at: URL(fileURLWithPath: .cacheFolderPath()), withIntermediateDirectories: true)
                    }
                    
                    try FileManager.default.copyItem(atPath: path, toPath: destination)
                    DispatchQueue.main.async {
                        completion(destination, nil)
                    }
                    
                } catch let err {
                    print("error: \(err.localizedDescription)")
                }
                return
            }
            
            FileCache.unzip(filePath: path,
                            completion: completion,
                            fail: fail)
        }, fail: fail)
    }
    
    static func unzip(filePath: String,
                      completion: @escaping DownloadCompletionClosure2,
                      fail: @escaping DownloadFailClosure) {
        
        let zipTempPath = createZipTempIfNeeded()
        
        let fileName = filePath.fileName.components(separatedBy: ".").first ?? ""
        DispatchQueue.global().async {
            
            let sourceZipFile = URL(fileURLWithPath: filePath)
            let destination = URL(fileURLWithPath: zipTempPath)
            
            do {
                try Zip.unzipFile(sourceZipFile, destination: destination, overwrite: true, password: nil)
                
                let allFilePaths = listFiles(path: zipTempPath)
                var lyricPath: String?
                var pitchPath: String?
                
                for path in allFilePaths {
                    if let typeStr = path.components(separatedBy: ".").last {
                        if typeStr == "xml" || typeStr == "lrc" {
                            lyricPath = path
                        }
                        if typeStr == "pitch" {
                            pitchPath = path
                        }
                    }
                }
                
                lyricPath = copyFile(sourcePath: lyricPath!, destPath: .cacheFolderPath())
                if lyricPath == nil {
                    fatalError()
                }
                if pitchPath != nil {
                    pitchPath = copyFile(sourcePath: pitchPath!, destPath: .cacheFolderPath())
                }
                
                DispatchQueue.main.async {
                    completion(lyricPath!, pitchPath)
                }
            } catch let err {
                DispatchQueue.main.async {
                    fail("unzip fail: \(err.localizedDescription)")
                }
            }
        }
    }
    
    static func createLyricsIfNeeded() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: .cacheFolderPath()) {
            return
        }
        do {
            try fileManager.createDirectory(atPath: .cacheFolderPath(), withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError()
        }
    }
    
    static func createZipTempIfNeeded() -> String {
        // 获取Library目录的路径
        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]

        // 拼接tempforzip文件夹的路径
        let tempPath = libraryPath + "/tempforzip"

        // 创建文件管理器对象
        let fileManager = FileManager.default

        // 判断tempforzip文件夹是否存在
        if fileManager.fileExists(atPath: tempPath) {
            // 如果存在，就删除它
            do {
                try fileManager.removeItem(atPath: tempPath)
            } catch {
                print("删除失败：\(error)")
            }
        }

        // 创建tempforzip文件夹
        do {
            try fileManager.createDirectory(atPath: tempPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("创建失败：\(error)")
        }
        return tempPath
    }
    
    // 定义一个函数，参数是文件夹的地址，返回值是文件路径地址数组
    static func listFiles(path: String) -> [String] {
        // 创建一个空数组，用来存储文件路径
        var files = [String]()
        // 创建一个文件管理器对象，用来访问文件系统
        let fileManager = FileManager.default
        // 尝试获取文件夹下的所有内容，包括子文件夹和文件
        if let contents = try? fileManager.contentsOfDirectory(atPath: path) {
            // 遍历每一个内容
            for item in contents {
                // 拼接完整的路径
                let fullPath = path + "/" + item
                // 尝试获取该路径的属性，判断是文件夹还是文件
                if let attributes = try? fileManager.attributesOfItem(atPath: fullPath) {
                    // 如果是文件夹，且不是隐藏的（以.开头的）
                    if attributes[.type] as? FileAttributeType == .typeDirectory && !item.hasPrefix(".") {
                        // 再次获取该文件夹下的所有内容，包括子文件夹和文件
                        if let subContents = try? fileManager.contentsOfDirectory(atPath: fullPath) {
                            // 遍历每一个内容
                            for subItem in subContents {
                                // 拼接完整的路径
                                let subFullPath = fullPath + "/" + subItem
                                // 尝试获取该路径的属性，判断是文件夹还是文件
                                if let subAttributes = try? fileManager.attributesOfItem(atPath: subFullPath) {
                                    // 如果是文件，且不是隐藏的（以.开头的）
                                    if subAttributes[.type] as? FileAttributeType == .typeRegular && !subItem.hasPrefix(".") {
                                        // 将该路径添加到数组中
                                        files.append(subFullPath)
                                    }
                                }
                            }
                        }
                    }
                    // 如果是文件，且不是隐藏的（以.开头的）
                    else if attributes[.type] as? FileAttributeType == .typeRegular && !item.hasPrefix(".") {
                        // 将该路径添加到数组中
                        files.append(fullPath)
                    }
                }
            }
        }
        // 返回数组
        return files
    }

    // 定义一个函数，参数是源文件地址和目标文件夹地址，返回值是目标文件地址
    static func copyFile(sourcePath: String, destPath: String) -> String {
        // 创建一个文件管理器对象，用来访问文件系统
        let fileManager = FileManager.default
        // 尝试获取源文件的文件名，即最后一个/后面的部分
        if let fileName = sourcePath.components(separatedBy: "/").last {
            // 拼接目标文件的完整路径，即在目标文件夹后面加上/和文件名
            let targetPath = destPath + "/" + fileName
            // 尝试复制源文件到目标文件
            if (try? fileManager.copyItem(atPath: sourcePath, toPath: targetPath)) != nil {
                // 如果成功，返回目标文件的路径
                return targetPath
            }
        }
        
        fatalError()
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
