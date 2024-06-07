//
//  Extensions.swift
//  Demo
//
//  Created by ZYP on 2024/6/5.
//

import AgoraRtcKit

extension Double {
    var keep3: Double {
        return Double(Darwin.round(self * 1000)/1000)
    }
}

extension AgoraMusicContentCenter {
    enum LyricFileType: Int {
        case xml = 0
        case lrc = 1
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
