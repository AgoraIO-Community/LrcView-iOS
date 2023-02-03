//
//  LogProvider.swift
//  
//
//  Created by ZYP on 2021/5/28.
//

import Foundation
import UIKit

class Log {
    fileprivate static let provider = LogProvider(domainName: "AgoraLyricsScore")
    
    static func errorText(text: String,
                          tag: String? = nil) {
        provider.errorText(text: text, tag: tag)
    }
    
    static func error(error: CustomStringConvertible,
                      tag: String? = nil) {
        provider.errorText(text: error.description, tag: tag)
    }
    
    static func info(text: String,
                     tag: String? = nil) {
        provider.info(text: text, tag: tag)
    }
    
    static func debug(text: String,
                      tag: String? = nil) {
        provider.debug(text: text, tag: tag)
    }
    
    static func warning(text: String,
                        tag: String? = nil) {
        provider.warning(text: text, tag: tag)
    }
}

class LogProvider {
    private let logger = Logger()
    private let queue = DispatchQueue(label: "LogProvider")
    
    fileprivate init(domainName: String) {
        logger.name = domainName
    }
    
    fileprivate func error(error: Error?,
                           tag: String?,
                           domainName: String) {
        guard let e = error else {
            return
        }
        var text = "<can not get error info>"
        if e.localizedDescription.count > 1 {
            text = e.localizedDescription
        }
        
        let err = e as CustomStringConvertible
        if err.description.count > 1 {
            text = err.description
        }
        
        errorText(text: text,
                  tag: tag)
    }
    
    fileprivate func errorText(text: String,
                               tag: String?) {
        log(type: .error,
            text: text,
            tag: tag)
    }
    
    fileprivate func info(text: String,
                          tag: String?) {
        log(type: .info,
            text: text,
            tag: tag)
    }
    
    fileprivate func warning(text: String,
                             tag: String?) {
        log(type: .warning,
            text: text,
            tag: tag)
    }
    
    fileprivate func debug(text: String,
                           tag: String?) {
        log(type: .debug,
            text: text,
            tag: tag)
    }
    
    fileprivate func log(type: AgoraLogType,
                         text: String,
                         tag: String?) {
        let levelName = type.name
        let string = getString(text: text,
                               tag: tag,
                               levelName: levelName)
        queue.async { [weak self] in
            self?.logger.write(string)
        }
    }
    
    private func getString(text: String,
                           tag: String?,
                           levelName: String) -> String {
        if let tag = tag {
            return "[\(levelName)][\(tag)]: " + text
        }
        return "[\(levelName)]: " + text
    }
}

extension LogProvider {
    enum AgoraLogType {
        case debug, info, warning, error
        fileprivate var name: String {
            switch self {
            case .debug:
                return "Debug"
            case .info:
                return "Info"
            case .error:
                return "Error"
            case .warning:
                return "Warning"
            }
        }
    }
}

