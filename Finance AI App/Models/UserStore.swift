import Foundation
import SwiftUI

@MainActor
class UserStore: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var loginError: String?
    
    private let userDefaultsKey = "currentUser"
    private let credentialsKey = "userCredentials"
    private var salaryCheckTimer: Timer?
    
    init() {
        loadUser()
        startSalaryCheckTimer()
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
    
    // MARK: - Salary Schedule Management
    
    func setSalarySchedule(_ schedule: SalarySchedule) {
        guard var user = currentUser else { return }
        user.salarySchedule = schedule
        currentUser = user
        saveUser()
    }
    
    func updateSalarySchedule(amount: Double? = nil, frequency: PayFrequency? = nil, nextPayDate: Date? = nil, isActive: Bool? = nil) {
        guard var user = currentUser, var schedule = user.salarySchedule else { return }
        
        if let amount = amount { schedule.amount = amount }
        if let frequency = frequency { schedule.frequency = frequency }
        if let nextPayDate = nextPayDate { schedule.nextPayDate = nextPayDate }
        if let isActive = isActive { schedule.isActive = isActive }
        
        user.salarySchedule = schedule
        currentUser = user
        saveUser()
    }
    
    func removeSalarySchedule() {
        guard var user = currentUser else { return }
        user.salarySchedule = nil
        currentUser = user
        saveUser()
    }
    
    // MARK: - FinBot Settings Management
    
    func updateFinBotSettings(_ settings: FinBotSettings) {
        guard var user = currentUser else { return }
        var updatedSettings = settings
        updatedSettings.updatedAt = Date()
        user.finBotSettings = updatedSettings
        currentUser = user
        saveUser()
    }
    
    func updateFinBotMood(_ mood: FinBotMood) {
        guard var user = currentUser else { return }
        user.finBotSettings.mood = mood
        user.finBotSettings.updatedAt = Date()
        currentUser = user
        saveUser()
    }
    
    func updateFinBotVoice(_ voice: FinBotVoice) {
        guard var user = currentUser else { return }
        user.finBotSettings.voice = voice
        user.finBotSettings.updatedAt = Date()
        currentUser = user
        saveUser()
    }
    
    func updateFinBotTheme(_ theme: FinBotTheme) {
        guard var user = currentUser else { return }
        user.finBotSettings.theme = theme
        user.finBotSettings.updatedAt = Date()
        currentUser = user
        saveUser()
    }
    
    func updateFinBotName(_ name: String) {
        guard var user = currentUser else { return }
        user.finBotSettings.customName = name
        user.finBotSettings.updatedAt = Date()
        currentUser = user
        saveUser()
    }
    
    // MARK: - Automatic Salary Crediting
    
    private func startSalaryCheckTimer() {
        // Check for salary crediting every hour
        salaryCheckTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndCreditSalary()
            }
        }
        
        // Check immediately on app launch
        checkAndCreditSalary()
    }
    
    func checkAndCreditSalary() {
        guard var user = currentUser,
              var schedule = user.salarySchedule,
              schedule.shouldCreditToday() else {
            return
        }
        
        // Credit the salary
        creditSalary(amount: schedule.amount)
        
        // Update schedule for next pay date
        schedule.lastCreditedDate = Date()
        schedule.updateNextPayDate()
        user.salarySchedule = schedule
        currentUser = user
        saveUser()
        
        // Post notification for successful crediting
        NotificationCenter.default.post(name: .salaryWasCredited, object: nil, userInfo: [
            "amount": schedule.amount,
            "nextPayDate": schedule.nextPayDate
        ])
    }
    
    private func creditSalary(amount: Double) {
        // This will integrate with TransactionStore to add income
        NotificationCenter.default.post(name: .addAutomaticIncome, object: nil, userInfo: [
            "amount": amount,
            "description": "Automatic Salary Credit",
            "date": Date()
        ])
    }
    
    deinit {
        salaryCheckTimer?.invalidate()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let salaryWasCredited = Notification.Name("salaryWasCredited")
    static let addAutomaticIncome = Notification.Name("addAutomaticIncome")
} 