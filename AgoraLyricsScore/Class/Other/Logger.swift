//
//  Logger.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/2/3.
//

import Foundation
import AgoraComponetLog

// MARK:- ConsoleLogger

public class ConsoleLoggerEx: NSObject, ILoggerEx {
    @objc public func onLog(content: String,
                            tag: String?,
                            time: String,
                            level: LoggerLevelEx) {
        
        let text = tag == nil ? "[\(time)][ALSEx][\(level)]: " + content : "[\(time)][ALSEx][\(level)][\(tag!)]: " + content
        print(text)
    }
}

// MARK:- FileLogger

public class FileLoggerEx: NSObject, ILoggerEx {
    let componetFileLogger: AgoraComponetFileLogger!
    let filePrefixName = "agora.AgoraLyricsScoreEx"
    let maxFileSizeOfBytes: UInt64 = 1024 * 1024 * 1
    let maxFileCount: UInt = 4
    let domainName = "ALSEx"
    
    @objc public override init() {
        self.componetFileLogger = AgoraComponetFileLogger(logFilePath: nil,
                                                          filePrefixName: filePrefixName,
                                                          maxFileSizeOfBytes: maxFileSizeOfBytes,
                                                          maxFileCount: maxFileCount,
                                                          domainName: domainName)
        super.init()
    }
    
    /// init
    /// - Parameter logFilePath: custom log file path.
    @objc public init(logFilePath: String) {
        componetFileLogger = AgoraComponetFileLogger(logFilePath: logFilePath,
                                                     filePrefixName: filePrefixName,
                                                     maxFileSizeOfBytes: maxFileSizeOfBytes,
                                                     maxFileCount: maxFileCount,
                                          
                                                     domainName: domainName)
    }
    
    @objc public func onLog(content: String,
                            tag: String?,
                            time: String,
                            level: LoggerLevelEx) {
        let newLevel = AgoraComponetLoggerLevel(rawValue: UInt(level.rawValue))!
        componetFileLogger.onLog(withContent: content, tag: tag, time: time, level: newLevel)
    }
}
