//
//  LyricsFileDownloaderProtocol.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/12/13.
//

import Foundation

/// the enum type to describe the error
@objc public enum DownloadErrorDomainType: Int {
    case general = 0
    /// repeat url request, a same url is requesting
    case repeatDownloading = 1
    /// error from http framework in ios, such as time out
    case httpDownloadError = 2
    /// http logic error, such as 400/500
    case httpDownloadErrorLogic = 3
    /// unzip fail
    case unzipFail = 4
    
    /// the string to indicate the type
    public var domain: String {
        switch self {
        case .general:
            return "io.agora.LyricsFileDownloader.general"
        case .repeatDownloading:
            return "io.agora.LyricsFileDownloader.repeatDownloading"
        case .httpDownloadError:
            return "io.agora.LyricsFileDownloader.httpDownloadError"
        case .httpDownloadErrorLogic:
            return "io.agora.LyricsFileDownloader.httpDownloadErrorLogic"
        case .unzipFail:
            return "io.agora.LyricsFileDownloader.unzipFail"
        }
    }
    
    /// the name to describe the type
    public var name: String {
        switch self {
        case .general:
            return "general"
        case .repeatDownloading:
            return "repeatDownloading"
        case .httpDownloadError:
            return "httpDownloadError"
        case .httpDownloadErrorLogic:
            return "httpDownloadErrorLogic"
        case .unzipFail:
            return "unzipFail"
        }
    }
}

/// the class to describe the error
public class DownloadError: NSError {
    /// the message to describe the error
    public let msg: String
    /// the type of different error
    public let domainType: DownloadErrorDomainType
    /// original error from http framework in ios, such as time out
    public var originalError: NSError?
    
    init(domainType: DownloadErrorDomainType, code: Int, msg: String) {
        self.domainType = domainType
        self.msg = msg
        super.init(domain: domainType.domain, code: code)
    }
    
    init(domainType: DownloadErrorDomainType, error: NSError) {
        self.domainType = domainType
        self.msg = error.localizedDescription
        self.originalError = error
        super.init(domain: domainType.domain, code: error.code)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var description: String {
        return "error: \(domainType.name) domain: \(domain) code:\(code) msg:\(msg) originalError:\(originalError?.localizedDescription ?? "nil")"
    }
}

@objc public protocol LyricsFileDownloaderDelegate: NSObjectProtocol {
    /// progress event
    /// - Parameters:
    ///   - progress: [0, 1], if equal `1`, means success
    func onLyricsFileDownloadProgress(requestId: Int, progress: Float)
     
    /// Completed event
    /// - Parameters:
    ///   - fileData: lyric data from file, if `nil` means fail
    ///   - error: if `nil` means success
    func onLyricsFileDownloadCompleted(requestId: Int, fileData: Data?, error: DownloadError?)
}
