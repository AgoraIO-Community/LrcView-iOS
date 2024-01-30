//
//  AgoraStringExtention.swift
//  AgoraKaraokeScore
//
//  Created by zhaoyongqiang on 2021/12/10.
//

import UIKit

extension String {
    // 获取时间格式
    func timeIntervalToMMSSFormat(interval: TimeInterval) -> String {
        if interval >= 3600 {
            let hour = interval / 3600
            let min = interval.truncatingRemainder(dividingBy: 3600) / 60
            let sec = interval.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)
            return String(format: "%02d:%02d:%02d", Int(hour), Int(min), Int(sec))
        } else {
            let min = interval / 60
            let sec = interval.truncatingRemainder(dividingBy: 60)
            return String(format: "%02d:%02d", Int(min), Int(sec))
        }
    }

    /**
     *  缓存文件夹路径
     */
    static func cacheFolderPath() -> String {
        return NSHomeDirectory().appending("/Library").appending("/MusicCaches").appending("/lyricFiles")
    }
    
    /// 下载目录
    static func downloadedFloderPath() -> String {
        return NSHomeDirectory().appending("/tmp").appending("/LyricDownloadFiles")
    }

    /**
     *  获取网址中的文件名
     */
    var fileName: String {
        components(separatedBy: "/").last ?? ""
    }
}

extension FileManager {
    static func createDirectoryIfNeeded(atPath path: String) {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                Log.debug(text: "给定的路径是一个文件: \(path)", tag: "Downloader Extension")
                return
            }
            Log.debug(text: "已存在：\(path)")
        } else {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                Log.debug(text: "已成功创建目录: \(path)", tag: "Downloader Extension")
            } catch {
                Log.errorText(text: "创建目录失败: \(error.localizedDescription)", tag: "Downloader Extension")
            }
        }
    }
}
