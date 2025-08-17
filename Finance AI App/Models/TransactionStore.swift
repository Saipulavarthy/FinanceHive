import Foundation

@MainActor
class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var budgets: [Budget] = []
    @Published var alerts: [BudgetAlert] = []
    
    private var achievementsStore: AchievementsStore?
    
    init() {
        setupNotificationObservers()
    }
    
    func setAchievementsStore(_ store: AchievementsStore) {
        self.achievementsStore = store
    }
    
    var totalIncome: Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Double {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Budget Management
    
    func addBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.category == budget.category }) {
            budgets[index] = budget
        } else {
            budgets.append(budget)
        }
        checkBudgetAlerts()
        
        achievementsStore?.unlockAchievement(id: "first_budget")
    }
    
    func getBudget(for category: Transaction.Category) -> Budget? {
        budgets.first { $0.category == category }
    }
    
    func checkBudgetAlerts() {
        alerts.removeAll()
        
        for budget in budgets {
            let spent = categoryTotal(for: budget.category)
            let percentageSpent = spent / budget.amount
            
            if percentageSpent >= 1.0 {
                alerts.append(BudgetAlert(
                    category: budget.category,
                    message: "You've exceeded your \(budget.category.rawValue) budget of $\(String(format: "%.2f", budget.amount))",
                    severity: .critical
                ))
            } else if percentageSpent >= budget.alertThreshold {
                alerts.append(BudgetAlert(
                    category: budget.category,
                    message: "You're approaching your \(budget.category.rawValue) budget limit",
                    severity: .warning
                ))
            }
        }
    }
    
    // MARK: - Spending Analysis
    
    func getMonthlySpending(for category: Transaction.Category, month: Date) -> Double {
        let calendar = Calendar.current
        return transactions
            .filter { transaction in
                transaction.type == .expense &&
                transaction.category == category &&
                calendar.isDate(transaction.date, equalTo: month, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getSpendingTrends() -> [SpendingInsight] {
        var insights: [SpendingInsight] = []
        let calendar = Calendar.current
        
        guard let currentMonth = calendar.date(byAdding: .month, value: 0, to: Date()),
              let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return insights
        }
        
        for category in Transaction.Category.allCases {
            let currentSpending = getMonthlySpending(for: category, month: currentMonth)
            let lastSpending = getMonthlySpending(for: category, month: lastMonth)
            
            if currentSpending > 0 || lastSpending > 0 {
                let percentageChange = lastSpending > 0 ?
                    ((currentSpending - lastSpending) / lastSpending) * 100 : 0
                
                insights.append(SpendingInsight(
                    category: category,
                    currentAmount: currentSpending,
                    previousAmount: lastSpending,
                    percentageChange: percentageChange
                ))
            }
        }
        
        return insights
    }
    
    func categoryTotal(for category: Transaction.Category) -> Double {
        transactions
            .filter { $0.type == .expense && $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Smart Suggestions
    
    func generateSuggestions() -> [FinancialSuggestion] {
        var suggestions: [FinancialSuggestion] = []
        
        // Check for high recurring expenses
        let recurringExpenses = findRecurringExpenses()
        for expense in recurringExpenses where expense.amount > 50 {
            suggestions.append(FinancialSuggestion(
                type: .subscription,
                message: "Consider reviewing your \(expense.description ?? "subscription") ($\(String(format: "%.2f", expense.amount))/month)"
            ))
        }
        
        // Check for overspending categories
        for budget in budgets {
            let spent = categoryTotal(for: budget.category)
            if spent > budget.amount * 1.2 { // 20% over budget
                suggestions.append(FinancialSuggestion(
                    type: .budgetOptimization,
                    message: "Your \(budget.category.rawValue) spending is significantly over budget. Consider setting a more realistic budget or finding ways to reduce expenses."
                ))
            }
        }
        
        return suggestions
    }
    
    private func findRecurringExpenses() -> [Transaction] {
        // Simple implementation - look for similar amounts in consecutive months
        let calendar = Calendar.current
        var recurringExpenses: [Transaction] = []
        
        for transaction in transactions where transaction.type == .expense {
            let amount = transaction.amount
            let similar = transactions.filter { t in
                t.type == .expense &&
                abs(t.amount - amount) < 1.0 && // Same amount (within $1)
                t.category == transaction.category &&
                !calendar.isDate(t.date, inSameDayAs: transaction.date)
            }
            
            if similar.count >= 2 && !recurringExpenses.contains(where: { $0.amount == amount }) {
                recurringExpenses.append(transaction)
            }
        }
        
        return recurringExpenses
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        checkBudgetAlerts()
        
        if transaction.type == .expense {
            achievementsStore?.didTrackExpense()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Existing methods...
}

// MARK: - Supporting Types

struct BudgetAlert: Identifiable {
    let id = UUID()
    let category: Transaction.Category
    let message: String
    let severity: AlertSeverity
    
    enum AlertSeverity {
        case warning
        case critical
    }
}

struct SpendingInsight: Identifiable {
    let id = UUID()
    let category: Transaction.Category
    let currentAmount: Double
    let previousAmount: Double
    let percentageChange: Double
}

struct FinancialSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let message: String
    
    enum SuggestionType {
        case subscription
        case budgetOptimization
        case saving
    }
}

// MARK: - TransactionStore Extension for Automatic Salary
extension TransactionStore {
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .addAutomaticIncome,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAutomaticIncome(notification)
        }
    }
    
    private func handleAutomaticIncome(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let amount = userInfo["amount"] as? Double,
              let description = userInfo["description"] as? String,
              let date = userInfo["date"] as? Date else {
            return
        }
        
        let transaction = Transaction(
            type: .income,
            amount: amount,
            category: .other, // or create a new category for salary
            date: date,
            description: description
        )
        
        addTransaction(transaction)
        
        // Trigger achievement unlock for automatic salary
        achievementsStore?.unlockAchievement(id: "auto_salary")
    }
} 