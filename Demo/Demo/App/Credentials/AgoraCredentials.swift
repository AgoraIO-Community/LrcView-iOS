import Foundation

enum CredentialValidationError: Error, Equatable {
    case invalidAppId
    case invalidCertificate
}

struct AgoraCredentials: Codable, Equatable {
    let appId: String
    let appCertificate: String

    init(appId: String, appCertificate: String) throws {
        let trimmedAppId = appId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCertificate = appCertificate.trimmingCharacters(in: .whitespacesAndNewlines)

        guard Self.isValidHexCredential(trimmedAppId) else {
            throw CredentialValidationError.invalidAppId
        }
        guard Self.isValidHexCredential(trimmedCertificate) else {
            throw CredentialValidationError.invalidCertificate
        }

        self.appId = trimmedAppId
        self.appCertificate = trimmedCertificate
    }

    private static func isValidHexCredential(_ value: String) -> Bool {
        let bytes = Array(value.utf8)
        return bytes.count == 32 && bytes.allSatisfy { byte in
            (48...57).contains(byte) || (65...70).contains(byte) || (97...102).contains(byte)
        }
    }
}
