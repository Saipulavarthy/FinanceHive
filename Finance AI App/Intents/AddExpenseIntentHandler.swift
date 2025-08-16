import Foundation
import Intents
import CoreData

// Simple Siri Shortcuts for basic voice commands
class SiriExpenseHandler: NSObject {
    
    static let shared = SiriExpenseHandler()
    
    // Handle basic Siri shortcuts without complex intents
    func handleVoiceExpense(userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == "com.financeapp.addexpense" else {
            return false
        }
        
        // Extract data from user activity
        if let userInfo = userActivity.userInfo,
           let amount = userInfo["amount"] as? Double,
           let merchant = userInfo["merchant"] as? String,
           let categoryString = userInfo["category"] as? String {
            
            let category = mapStringToCategory(categoryString)
            return saveExpenseToDatabase(amount: amount, merchant: merchant, category: category)
        }
        
        return false
    }
    
    private func mapStringToCategory(_ categoryString: String) -> Transaction.Category {
        let lowercased = categoryString.lowercased()
        
        switch lowercased {
        case "food", "restaurant", "dining", "groceries", "grocery":
            return .groceries
        case "transport", "transportation", "travel", "gas", "fuel":
            return .transportation
        case "entertainment", "movie", "games", "fun":
            return .entertainment
        case "utilities", "electric", "water", "internet", "phone":
            return .utilities
        case "rent", "housing", "mortgage":
            return .rent
        default:
            return .other
        }
    }
    
    private func saveExpenseToDatabase(amount: Double, merchant: String, category: Transaction.Category) -> Bool {
        let persistentContainer = PersistenceController.shared.container
        let context = persistentContainer.viewContext
        
        do {
            let expense = RecurringExpense(context: context)
            expense.amount = amount
            expense.category = category.rawValue
            expense.note = "Added via Siri"
            expense.date = Date()
            expense.isRecurring = false
            expense.repeatInterval = nil
            
            try context.save()
            return true
        } catch {
            print("Failed to save Siri expense: \(error)")
            return false
        }
    }
}
