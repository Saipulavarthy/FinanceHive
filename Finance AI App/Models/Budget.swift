import Foundation

struct Budget: Identifiable, Codable {
    let id: UUID
    let category: Transaction.Category
    var amount: Double
    var alertThreshold: Double // Percentage (0.0 to 1.0) at which to alert user
    
    init(category: Transaction.Category, amount: Double, alertThreshold: Double = 0.8) {
        self.id = UUID()
        self.category = category
        self.amount = amount
        self.alertThreshold = alertThreshold
    }
} 