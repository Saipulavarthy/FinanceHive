import Foundation

@MainActor
class SiriShortcutsManager: ObservableObject {
    static let shared = SiriShortcutsManager()
    
    @Published var isSetup = false
    
    private init() {
        setupShortcuts()
    }
    
    // MARK: - Setup and Donation
    
    func setupShortcuts() {
        // Setup basic user activities for Siri Shortcuts
        donateCommonActivities()
        isSetup = true
    }
    
    private func donateCommonActivities() {
        // Donate common expense activities
        let commonActivities = [
            ("Log my expense", "Add expense to Finance App"),
            ("Record spending", "Record new spending"),
            ("Add transaction", "Add new transaction")
        ]
        
        for (phrase, title) in commonActivities {
            let userActivity = NSUserActivity(activityType: "com.financeapp.addexpense")
            userActivity.title = title
            userActivity.suggestedInvocationPhrase = phrase
            userActivity.isEligibleForSearch = true
            userActivity.isEligibleForPrediction = true
            userActivity.isEligibleForHandoff = false
            
            userActivity.becomeCurrent()
        }
    }
    
    // MARK: - User Activity Donation
    
    func donateExpenseActivity(amount: Double, merchant: String, category: Transaction.Category) {
        let userActivity = NSUserActivity(activityType: "com.financeapp.addexpense")
        userActivity.title = "Add \(merchant) Expense"
        userActivity.userInfo = [
            "amount": amount,
            "merchant": merchant,
            "category": category.rawValue
        ]
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Log \(merchant) expense"
        
        userActivity.becomeCurrent()
    }
    
    func donateVoiceExpenseActivity() {
        let userActivity = NSUserActivity(activityType: "com.financeapp.voiceexpense")
        userActivity.title = "Voice Expense Entry"
        userActivity.isEligibleForSearch = true
        userActivity.isEligibleForPrediction = true
        userActivity.suggestedInvocationPhrase = "Voice expense logging"
        
        userActivity.becomeCurrent()
    }
}
