//
//  Extensions.swift
//  Demo
//
//  Created by ZYP on 2024/6/5.
//

import AgoraRtcKit

typealias AgoraMusicContentCenterPreloadStatus = AgoraMusicContentCenterPreloadState
typealias AgoraMusicContentCenterStatusCode = AgoraMusicContentCenterStateReason

extension Double {
    var keep3: Double {
        return Double(Darwin.round(self * 1000)/1000)
    }
}

extension AgoraMusicContentCenter {
    enum LyricFileType: Int, CustomStringConvertible {
        case xml = 0
        case lrc = 1
        
        var description: String {
            return self == .xml ? "xml" : "lrc"
        }
    }
}

extension AgoraMusicContentCenterPreloadStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .OK:
            return "OK"
        case .error:
            return "error"
        case .preloading:
            return "preloading"
        case .removeCache:
            return "removeCache"
        @unknown default:
            fatalError()
        }
    }
}

extension AgoraMusicContentCenterStatusCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .OK:
            return "OK"
        case .error:
            return "error"
        case .errorGateway:
            return "errorGateway"
        case .errorMusicLoading:
            return "errorMusicLoading"
        case .errorInternalDataParse:
            return "errorInternalDataParse"
        case .errorPermissionAndResource:
            return "errorPermissionAndResource"
        case .errorHttpInternalError:
            return "errorHttpInternalError"
        case .errorMusicDecryption:
            return "errorMusicDecryption"
        @unknown default:
            fatalError()
        }
    }
}
