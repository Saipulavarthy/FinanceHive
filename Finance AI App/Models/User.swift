import Foundation
import CryptoKit

struct User: Codable {
    let id: String
    var name: String
    var email: String
    var passwordHash: String
    var notificationsEnabled: Bool
    var userProfile: UserProfile
    
    init(id: String = UUID().uuidString, name: String, email: String, password: String, notificationsEnabled: Bool = true, userProfile: UserProfile = UserProfile.default()) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = User.hash(password)
        self.notificationsEnabled = notificationsEnabled
        self.userProfile = userProfile
    }
    
    static func hash(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func verifyPassword(_ password: String) -> Bool {
        return Self.hash(password) == passwordHash
    }
} 