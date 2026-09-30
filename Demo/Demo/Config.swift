//
//  Config.swift
//  Demo
//
//  Created by ZYP on 2022/12/23.
//

import Foundation

struct Config {
    
    static let channelId = "DRMTest001"
    static let hostUid: UInt = 1
    static let audioUid: UInt = 2
    static let playerUid: Int = 100
    static let mccUid: Int = 333
    
    static let rtcAppId = LocalMccConfig.rtcAppId
    static let rtcCertificate = LocalMccConfig.rtcCertif
    static let mccAppId = LocalMccConfig.mccAppId
    static let mccCertificate = LocalMccConfig.mccCertif
    static var mccDomain: String? {
        let domain = LocalMccConfig.mccDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        return domain.isEmpty ? nil : domain
    }
    static let accessUrl = LocalMccConfig.accessUrl
    
    /// ysd important vars
    static let pid = LocalMccConfig.pid
    static let pKey = LocalMccConfig.pKey
    static var token: String? = nil
    static var userId: String? = nil
}
