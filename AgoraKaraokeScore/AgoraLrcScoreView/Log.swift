//
//  LogProvider.swift
//  
//
//  Created by ZYP on 2021/5/28.
//

import Foundation
import UIKit

class Log {
    fileprivate static let provider = LogProvider(domainName: "ALRC")
    
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
    
    static func set(delegate: AgoraLogDelegate?) {
        provider.delegate = delegate
    }
}

class LogProvider {
    private let domainName: String
    private let formatter = DateFormatter()
    fileprivate weak var delegate: AgoraLogDelegate?
    private let queue = DispatchQueue(label: "queue.agoraLRC.LogProvider")
    
    fileprivate init(domainName: String) {
        self.domainName = domainName
        formatter.dateFormat = "MM-dd HH:mm:ss"
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
        queue.async { [weak self] in
            self?._log(type: type,
                       text: text,
                       tag: tag)
        }
    }
    
    fileprivate func _log(type: AgoraLogType,
                          text: String,
                          tag: String?) {
        let levelName = type.name
        let content = getString(text: text,
                                tag: tag,
                                levelName: levelName)
        let time = formatter.string(from: Date())
        let msg = "\(time) \(content)"
        delegate?.onLog?(msg: msg)
    }
    
    private func getString(text: String,
                           tag: String?,
                           levelName: String) -> String {
        if let `tag` = tag {
            return "[\(domainName)][\(levelName)][\(tag)]: " + text
        }
        return "[\(domainName)][\(levelName)]: " + text
    }
}

extension LogProvider {
    enum AgoraLogType {
        case debug, info, warning, error
        fileprivate var name: String {
            switch self {
            case .debug:
                return "D"
            case .info:
                return "I"
            case .error:
                return "E"
            case .warning:
                return "W"
            }
        }
    }
}

@objc(AgoraLogDelegate)
public protocol AgoraLogDelegate: NSObjectProtocol {
    /// 日志回调（在子线程进行）
    @objc optional func onLog(msg: String)
}
