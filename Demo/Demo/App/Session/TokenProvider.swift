import Foundation
import RTMTokenBuilder

struct KaraokeAccess: Equatable {
    let uid: UInt
    let channelName: String
    let rtcToken: String
    let mccToken: String
}

protocol TokenProviding {
    func makeAccess(credentials: AgoraCredentials) throws -> KaraokeAccess
}

enum TokenProviderError: Error, Equatable {
    case invalidSessionIdentity
    case generationFailed
}

final class LocalTokenProvider: TokenProviding {
    private let uid: () -> UInt
    private let channel: () -> String

    init(
        uid: @escaping () -> UInt = { UInt.random(in: 1...UInt(Int32.max)) },
        channel: @escaping () -> String = {
            "kl-" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
    ) {
        self.uid = uid
        self.channel = channel
    }

    func makeAccess(credentials: AgoraCredentials) throws -> KaraokeAccess {
        let value = uid()
        let channelName = channel()
        guard value > 0,
              value <= UInt(Int32.max),
              !channelName.isEmpty,
              channelName.utf8.count < 64 else {
            throw TokenProviderError.invalidSessionIdentity
        }

        let rtcToken = TokenBuilder.rtcToken2(
            credentials.appId,
            appCertificate: credentials.appCertificate,
            uid: Int32(value),
            channelName: channelName
        )
        let mccToken = TokenBuilder.buildRtmToken2(
            credentials.appId,
            appCertificate: credentials.appCertificate,
            userUuid: String(value)
        )
        guard rtcToken.hasPrefix("007"), mccToken.hasPrefix("007") else {
            throw TokenProviderError.generationFailed
        }

        return KaraokeAccess(
            uid: value,
            channelName: channelName,
            rtcToken: rtcToken,
            mccToken: mccToken
        )
    }
}
