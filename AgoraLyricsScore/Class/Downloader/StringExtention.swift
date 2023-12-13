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
        return NSHomeDirectory().appending("/Library").appending("/MusicCaches")
    }

    /**
     *  获取网址中的文件名
     */
    var fileName: String {
        components(separatedBy: "/").last ?? ""
    }
}
