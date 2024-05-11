//
//  Log.swift
//  Demo
//
//  Created by ZYP on 2024/5/11.
//

import Foundation
import AgoraComponetLog

class Log {
    static func setupLogger() {
        let fileLogger = AgoraComponetFileLogger(logFilePath: nil,
                                                 filePrefixName: "AgoraLyricsDemo",
                                                 maxFileSizeOfBytes: 1 * 1024 * 1024,
                                                 maxFileCount: 5,
                                                 domainName: "ALD")
        let consoleLogger = AgoraComponetConsoleLogger(domainName: "ALD")
        AgoraComponetLog.setLoggers([fileLogger, consoleLogger])
    }
    
    static func errorText(text: String,
                          tag: String? = nil) {
        AgoraComponetLog.error(withText: text, tag: tag)
    }
    
    static func error(error: CustomStringConvertible,
                      tag: String? = nil) {
        AgoraComponetLog.error(withText: error.description, tag: tag)
    }
    
    static func info(text: String,
                     tag: String? = nil) {
        AgoraComponetLog.info(withText: text, tag: tag)
    }
    
    static func debug(text: String,
                      tag: String? = nil) {
        AgoraComponetLog.debug(withText: text, tag: tag)
    }
    
    static func warning(text: String,
                        tag: String? = nil) {
        AgoraComponetLog.warning(withText: text, tag: tag)
    }
}
