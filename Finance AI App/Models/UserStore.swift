import Foundation
import SwiftUI

@MainActor
class UserStore: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var loginError: String?
    
    private let userDefaultsKey = "currentUser"
    private let credentialsKey = "userCredentials"
    
    init() {
        loadUser()
    }
    
    func signUp(name: String, email: String, password: String) -> Bool {
        // Check if email already exists
        if let existingCredentials = UserDefaults.standard.dictionary(forKey: credentialsKey) as? [String: String],
           existingCredentials.keys.contains(email) {
            return false
        }
        
        let user = User(name: name, email: email, password: password)
        currentUser = user
        isAuthenticated = true
        
        // Save user credentials
        var credentials = UserDefaults.standard.dictionary(forKey: credentialsKey) as? [String: String] ?? [:]
        credentials[email] = User.hash(password)
        UserDefaults.standard.set(credentials, forKey: credentialsKey)
        
        saveUser()
        return true
    }
    
    func signIn(email: String, password: String) -> Bool {
        guard let credentials = UserDefaults.standard.dictionary(forKey: credentialsKey) as? [String: String],
              let storedHash = credentials[email],
              storedHash == User.hash(password),
              let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: userData),
              user.email == email else {
            return false
        }
        
        currentUser = user
        isAuthenticated = true
        return true
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
    
    private func saveUser() {
        if let encoded = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    // Add: Update user profile fields
    func updateRiskLevel(_ risk: RiskLevel) {
        guard var user = currentUser else { return }
        user.userProfile.riskLevel = risk
        user.userProfile.updatedAt = Date()
        currentUser = user
        saveUser()
    }
    func updateInvestmentGoal(_ goal: InvestmentGoal) {
        guard var user = currentUser else { return }
        user.userProfile.investmentGoal = goal
        user.userProfile.updatedAt = Date()
        currentUser = user
        saveUser()
    }
    func updatePreferredSectors(_ sectors: [String]) {
        guard var user = currentUser else { return }
        user.userProfile.preferredSectors = sectors
        user.userProfile.updatedAt = Date()
        currentUser = user
        saveUser()
    }
    func setIsBeginner(_ isBeginner: Bool) {
        guard var user = currentUser else { return }
        user.userProfile.isBeginner = isBeginner
        user.userProfile.updatedAt = Date()
        currentUser = user
        saveUser()
    }
} 