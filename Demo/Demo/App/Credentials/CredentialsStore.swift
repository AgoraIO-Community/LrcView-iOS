import Foundation
import Security

protocol CredentialsStoring {
    func load() throws -> AgoraCredentials?
    func save(_ credentials: AgoraCredentials) throws
    func clear() throws
}

enum KeychainStoreError: Error, Equatable {
    case unexpectedStatus(OSStatus)
}

final class KeychainCredentialsStore: CredentialsStoring {
    private static let account = "agora-credentials"

    private let service: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(service: String = "io.agora.KLyricsDemo.credentials") {
        self.service = service
    }

    func load() throws -> AgoraCredentials? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainStoreError.unexpectedStatus(status)
        }
        return try decoder.decode(AgoraCredentials.self, from: data)
    }

    func save(_ credentials: AgoraCredentials) throws {
        try clear()

        var query = baseQuery
        query[kSecValueData as String] = try encoder.encode(credentials)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainStoreError.unexpectedStatus(status)
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainStoreError.unexpectedStatus(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.account
        ]
    }
}
