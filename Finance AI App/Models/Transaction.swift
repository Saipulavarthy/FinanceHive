import Foundation
import Charts

struct Transaction: Identifiable, Codable {
    var id = UUID()
    var type: TransactionType
    var amount: Double
    var category: Category
    var date: Date
    var description: String?
    
    enum TransactionType: String, Codable {
        case income
        case expense
    }
    
    enum Category: String, Codable, CaseIterable {
        case rent = "Rent"
        case groceries = "Groceries"
        case entertainment = "Entertainment"
        case utilities = "Utilities"
        case transportation = "Transportation"
        case subscriptions = "Subscriptions"
        case insurance = "Insurance"
        case other = "Other"
    }
    
    static func category(for input: String) -> Category {
        let lowercased = input.lowercased()
        let keywordToCategory: [String: Category] = [
            // Transportation
            "uber": .transportation,
            "lyft": .transportation,
            "shell": .transportation,
            "chevron": .transportation,
            // Groceries
            "starbucks": .groceries,
            "mcdonald": .groceries,
            "burger king": .groceries,
            "grocery": .groceries,
            "whole foods": .groceries,
            "trader joe": .groceries,
            // Entertainment
            "airbnb": .entertainment,
            "delta": .entertainment,
            "movie": .entertainment,
            "game": .entertainment,
            // Subscriptions
            "subscription": .subscriptions,
            "netflix": .subscriptions,
            "spotify": .subscriptions,
            "apple music": .subscriptions,
            "youtube premium": .subscriptions,
            "disney+": .subscriptions,
            "hulu": .subscriptions,
            "amazon prime": .subscriptions,
            "adobe": .subscriptions,
            "microsoft office": .subscriptions,
            "dropbox": .subscriptions,
            "icloud": .subscriptions,
            "gym membership": .subscriptions,
            "fitness": .subscriptions,
            // Utilities
            "comcast": .utilities,
            "att": .utilities,
            "verizon": .utilities,
            "electricity": .utilities,
            "gas bill": .utilities,
            "internet": .utilities,
            "cable": .utilities,
            "phone bill": .utilities,
            // Insurance
            "insurance": .insurance,
            "car insurance": .insurance,
            "health insurance": .insurance,
            "renters insurance": .insurance,
            // Rent
            "rent": .rent,
            "mortgage": .rent,
            // Default catch-all for other merchants
            "walmart": .other,
            "target": .other,
            "amazon": .other
        ]
        for (keyword, category) in keywordToCategory {
            if lowercased.contains(keyword) {
                return category
            }
        }
        return .other
    }
}

// Add this extension to make Category conform to Plottable
extension Transaction.Category: Plottable {
    public var primitivePlottable: String {
        self.rawValue
    }
} 