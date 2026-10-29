import Foundation
import Security

/// A random id for this install, sent as X-Device-ID so the server can count free checks.
/// Kept in the keychain (not UserDefaults) so deleting and reinstalling doesn't reset the quota.
enum DeviceID {
    private static let account = "deviceID"

    static let value: String = (load() ?? save(UUID())).uuidString

    private static var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Bundle.main.bundleIdentifier ?? "ScamSense",
         kSecAttrAccount as String: account]
    }

    private static func load() -> UUID? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data, let text = String(data: data, encoding: .utf8) else { return nil }
        return UUID(uuidString: text)
    }

    private static func save(_ id: UUID) -> UUID {
        var item = baseQuery
        item[kSecValueData as String] = Data(id.uuidString.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
        return id
    }
}
