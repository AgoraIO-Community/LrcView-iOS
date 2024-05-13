//
//  Config.swift
//  Demo
//
//  Created by ZYP on 2022/12/23.
//

import Foundation

struct Config {
    /// ignore
    static let channelId = "DRMTest001"
    static let hostUid: UInt = 1
    static let audioUid: UInt = 2
    static let playerUid: Int = 100
    static let mccUid: Int = 333
    
    /// agora important vars
    static let rtcAppId = <#rtcAppId#>
    static var mccAppId = <#mccAppId#>
    static var mccCertificate = <#mccCertificate#>
    
    /// ysd important vars
    static let pid = <#pid#>
    static let pKey = <#pKey#>
    static var token: String? = <#token#>
    static var userId: String? = <#userId#>
}
