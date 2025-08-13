import Foundation
import Security
import CryptoKit
import LocalAuthentication

class SecurityManager {
    static let shared = SecurityManager()
    
    private let keychainService = "com.financeapp.secure"
    private let encryptionKeyIdentifier = "encryptionKey"
    
    private init() {}
    
    // MARK: - Keychain Operations
    
    func saveToKeychain(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    // MARK: - Encryption/Decryption
    
    func encrypt(_ data: Data) -> Data? {
        guard let key = getOrCreateEncryptionKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    func decrypt(_ data: Data) -> Data? {
        guard let key = getOrCreateEncryptionKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    private func getOrCreateEncryptionKey() -> SymmetricKey? {
        // Try to load existing key
        if let keyData = loadFromKeychain(key: encryptionKeyIdentifier) {
            return SymmetricKey(data: keyData)
        }
        
        // Create new key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        if saveToKeychain(key: encryptionKeyIdentifier, data: keyData) {
            return key
        }
        
        return nil
    }
    
    // MARK: - Secure Data Storage
    
    func secureStore(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8),
              let encryptedData = encrypt(data) else { return false }
        
        return saveToKeychain(key: key, data: encryptedData)
    }
    
    func secureRetrieve(forKey key: String) -> String? {
        guard let encryptedData = loadFromKeychain(key: key),
              let decryptedData = decrypt(encryptedData) else { return nil }
        
        return String(data: decryptedData, encoding: .utf8)
    }
    
    // MARK: - Biometric Authentication
    
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        let reason = "Authenticate to access your financial data"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    // MARK: - Data Sanitization
    
    func sanitizeInput(_ input: String) -> String {
        // Remove potentially dangerous characters
        let dangerousChars = CharacterSet(charactersIn: "<>\"'&")
        return input.components(separatedBy: dangerousChars).joined()
    }
    
    // MARK: - Secure Deletion
    
    func secureDelete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    func wipeAllData() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
