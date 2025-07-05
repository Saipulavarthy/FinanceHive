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
            "netflix": .entertainment,
            "spotify": .entertainment,
            "airbnb": .entertainment,
            "delta": .entertainment,
            // Utilities
            "comcast": .utilities,
            "att": .utilities,
            "verizon": .utilities,
            // Rent
            "rent": .rent,
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