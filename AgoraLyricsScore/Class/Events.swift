//
//  Events.swift
//  NewApi
//
//  Created by ZYP on 2022/11/22.
//

import Foundation

@objc public protocol KaraokeDelegate: NSObjectProtocol {
    /// 拖拽歌词结束后回调
    /// - Note: 当 `KaraokeConfig.lyricConfig.draggable == true` 且 用户进行拖动歌词时候 调用
    /// - Parameters:
    ///   - view: KaraokeView
    ///   - position: 当前时间点 (ms)
    @objc optional func onKaraokeView(view: KaraokeView, didDragTo position: UInt)
}

/// 日志协议
@objc public protocol ILogger {
    /// 日志输出
    /// - Note: 在子线程执行
    /// - Parameters:
    ///   - content: 内容
    ///   - tag: 标签
    ///   - time: 时间
    ///   - level: 等级
    @objc func onLog(content: String, tag: String?, time: String, level: LoggerLevel)
}

@objc public enum LoggerLevel: UInt8, CustomStringConvertible {
    case debug, info, warning, error
    
    public var description: String {
        switch self {
        case .debug:
            return "D"
        case .info:
            return "I"
        case .warning:
            return "W"
        case .error:
            return "E"
        }
    }
}
