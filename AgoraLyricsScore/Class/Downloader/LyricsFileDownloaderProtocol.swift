//
//  LyricsFileDownloaderProtocol.swift
//  AgoraLyricsScore
//
//  Created by ZYP on 2023/12/13.
//

import Foundation

public enum DownloadErrorCodeType: Int {
    case general = 0
    /// repeat url request, a same url is requesting
    case repeatDownloading = 1
    case httpDownloadError = 2
    case unzipFail = 3
}

public class DownloadError: NSError {
    public let msg: String
    public let codeType: DownloadErrorCodeType
    
    init(codeType: DownloadErrorCodeType, msg: String) {
        self.codeType = codeType
        self.msg = msg
        super.init(domain: "com.agora.LyricsFileDownloader", code: codeType.rawValue)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
