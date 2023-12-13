//
//  Logger.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/2/3.
//

import Foundation
import AgoraComponetLog

// MARK:- ConsoleLogger

public class ConsoleLogger: NSObject, ILogger {
    @objc public func onLog(content: String,
                            tag: String?,
                            time: String,
                            level: LoggerLevel) {
        
        let text = tag == nil ? "[\(time)][ALS][\(level)]: " + content : "[\(time)][ALS][\(level)][\(tag!)]: " + content
        print(text)
    }
}

// MARK:- FileLogger

public class FileLogger: NSObject, ILogger {
    let componetFileLogger: AgoraComponetFileLogger!
    @objc public init(logFilePath: String? = nil) {
        componetFileLogger = AgoraComponetFileLogger(logFilePath: logFilePath,
                                                     filePrefixName: "agora.AgoraLyricsScore",
                                                     maxFileSizeOfBytes: 1024 * 1024 * 2,
                                                     maxFileCount: 8,
                                                     domainName: "ALS")
    }
    
    @objc public func onLog(content: String,
                            tag: String?,
                            time: String,
                            level: LoggerLevel) {
        let newLevel = AgoraComponetLoggerLevel(rawValue: UInt(level.rawValue))!
        componetFileLogger.onLog(withContent: content, tag: tag, time: time, level: newLevel)
    }
}
