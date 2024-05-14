//
//  Log.swift
//  Demo
//
//  Created by ZYP on 2024/5/11.
//

import Foundation
import AgoraComponetLog

class Log {
    static let shared = Log()
    var componetLog: AgoraComponetLog!
    
    static func setupLogger() {
        let fileLogger = AgoraComponetFileLogger(logFilePath: nil,
                                                 filePrefixName: "AgoraLyricsDemo",
                                                 maxFileSizeOfBytes: 1 * 1024 * 1024,
                                                 maxFileCount: 5,
                                                 domainName: "ALD")
        let consoleLogger = AgoraComponetConsoleLogger(domainName: "ALD")
        shared.componetLog = AgoraComponetLog(queueTag: "AgoraLyricsDemo")
        shared.componetLog.configLoggers([fileLogger, consoleLogger])
    }
    
    static func errorText(text: String,
                          tag: String? = nil) {
        shared.componetLog.error(withText: text, tag: tag)
    }
    
    static func error(error: CustomStringConvertible,
                      tag: String? = nil) {
        shared.componetLog.error(withText: error.description, tag: tag)
    }
    
    static func info(text: String,
                     tag: String? = nil) {
        shared.componetLog.info(withText: text, tag: tag)
    }
    
    static func debug(text: String,
                      tag: String? = nil) {
        shared.componetLog.debug(withText: text, tag: tag)
    }
    
    static func warning(text: String,
                        tag: String? = nil) {
        shared.componetLog.warning(withText: text, tag: tag)
    }
}
