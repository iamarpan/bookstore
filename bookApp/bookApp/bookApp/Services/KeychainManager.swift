import Foundation
import Security

/// Keychain wrapper for secure token storage
class KeychainManager {
    static let shared = KeychainManager()
    
    private let serviceName = "com.bookshare.app"
    
    private init() {}
    
    // MARK: - Token Storage
    
    /// Save access token to keychain
    func saveAccessToken(_ token: String) -> Bool {
        return save(key: "accessToken", value: token)
    }
    
    /// Get access token from keychain
    func getAccessToken() -> String? {
        return get(key: "accessToken")
    }
    
    /// Save refresh token to keychain
    func saveRefreshToken(_ token: String) -> Bool {
        return save(key: "refreshToken", value: token)
    }
    
    /// Get refresh token from keychain
    func getRefreshToken() -> String? {
        return get(key: "refreshToken")
    }
    
    /// Clear all tokens (logout)
    func clearTokens() {
        delete(key: "accessToken")
        delete(key: "refreshToken")
    }
    
    // MARK: - Generic Keychain Operations
    
    /// Save a value to keychain
    private func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        // Delete any existing item
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Saved \(key) to keychain")
            return true
        } else {
            print("❌ Failed to save \(key) to keychain: \(status)")
            return false
        }
    }
    
    /// Get a value from keychain
    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Delete a value from keychain
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
