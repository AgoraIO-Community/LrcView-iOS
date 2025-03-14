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

    static let mccDomain: String? = "api-test.agora.io"
    
    /// agora important vars
    static let rtcAppId = "ba6ff465978449e89a66641c7e95f157"
    static let mccAppId = "b792b33fc5f046ffa22776bf8d140e4d"
    static let mccCertificate = "cedaa9beef5c4378ad9675c4e0ca0af2"
    
    /// ysd important vars
    static let pid = "203321"
    static let pKey = "4059144a3ace4a23a351ca3f96e6693d"
    static var token: String? = nil
    static var userId: String? = nil
    
    /// ysd test vars
    static let accessUrl = "https://yapi-test.tuwan.com/yinsuda/getUserData?uid=1"
}
