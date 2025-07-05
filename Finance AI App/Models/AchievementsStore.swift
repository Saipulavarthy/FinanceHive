import Foundation
import Combine

@MainActor
class AchievementsStore: ObservableObject {
    @Published var achievements: [Achievement]
    @Published var expenseTrackingStreak: Int = 0
    
    private var lastTransactionDate: Date?

    init() {
        // Define all possible achievements
        self.achievements = [
            Achievement(id: "first_expense", title: "Tracker Started", description: "You added your first expense.", icon: "pencil.and.outline", isUnlocked: false),
            Achievement(id: "first_budget", title: "Budget Setter", description: "You set your first budget.", icon: "chart.pie.fill", isUnlocked: false),
            Achievement(id: "streak_3_days", title: "On a Roll", description: "Tracked expenses for 3 days in a row.", icon: "flame.fill", isUnlocked: false)
        ]
        
        // TODO: Load saved state from UserDefaults or other persistence
    }
    
    func unlockAchievement(id: String) {
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            achievements[index].isUnlocked = true
        }
    }
    
    func didTrackExpense() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = lastTransactionDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            if let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day {
                if diff == 1 {
                    expenseTrackingStreak += 1
                } else if diff > 1 {
                    expenseTrackingStreak = 1 // Reset streak
                }
            }
        } else {
            expenseTrackingStreak = 1
        }
        
        lastTransactionDate = today
        unlockAchievement(id: "first_expense")
        
        if expenseTrackingStreak >= 3 {
            unlockAchievement(id: "streak_3_days")
        }
    }
} 