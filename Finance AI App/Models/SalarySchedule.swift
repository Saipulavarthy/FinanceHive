import Foundation

enum PayFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    
    var id: String { self.rawValue }
    
    var daysInterval: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30 // Approximate for monthly
        }
    }
    
    var description: String {
        switch self {
        case .weekly: return "Every week"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Every month"
        }
    }
}

struct SalarySchedule: Codable, Identifiable {
    let id = UUID()
    var amount: Double
    var frequency: PayFrequency
    var nextPayDate: Date
    var isActive: Bool
    var lastCreditedDate: Date?
    
    init(amount: Double, frequency: PayFrequency, nextPayDate: Date, isActive: Bool = true) {
        self.amount = amount
        self.frequency = frequency
        self.nextPayDate = nextPayDate
        self.isActive = isActive
        self.lastCreditedDate = nil
    }
    
    // Calculate next pay date based on frequency
    mutating func updateNextPayDate() {
        let calendar = Calendar.current
        
        switch frequency {
        case .weekly:
            nextPayDate = calendar.date(byAdding: .day, value: 7, to: nextPayDate) ?? nextPayDate
        case .biweekly:
            nextPayDate = calendar.date(byAdding: .day, value: 14, to: nextPayDate) ?? nextPayDate
        case .monthly:
            nextPayDate = calendar.date(byAdding: .month, value: 1, to: nextPayDate) ?? nextPayDate
        }
    }
    
    // Check if salary should be credited today
    func shouldCreditToday() -> Bool {
        guard isActive else { return false }
        
        let today = Date()
        let calendar = Calendar.current
        
        // Check if today is the pay date or after
        return calendar.isDate(today, inSameDayAs: nextPayDate) || today > nextPayDate
    }
    
    // Get days until next pay
    func daysUntilNextPay() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        if let days = calendar.dateComponents([.day], from: today, to: nextPayDate).day {
            return max(0, days)
        }
        return 0
    }
    
    // Format next pay date for display
    func formattedNextPayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: nextPayDate)
    }
}
