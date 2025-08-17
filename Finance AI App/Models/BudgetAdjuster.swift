import Foundation
import SwiftUI

// MARK: - Budget Adjustment Models

enum AdjustmentReason: String, Codable, CaseIterable {
    case overspending = "Overspending detected"
    case underspending = "Underspending opportunity"
    case seasonalTrend = "Seasonal spending pattern"
    case emergencyFund = "Emergency fund protection"
    case goalPriority = "Savings goal priority"
    case incomeChange = "Income change detected"
    
    var icon: String {
        switch self {
        case .overspending: return "exclamationmark.triangle.fill"
        case .underspending: return "arrow.down.circle.fill"
        case .seasonalTrend: return "calendar.circle.fill"
        case .emergencyFund: return "shield.fill"
        case .goalPriority: return "target"
        case .incomeChange: return "dollarsign.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .overspending: return .red
        case .underspending: return .green
        case .seasonalTrend: return .blue
        case .emergencyFund: return .orange
        case .goalPriority: return .purple
        case .incomeChange: return .teal
        }
    }
}

struct BudgetAdjustment: Identifiable, Codable {
    let id: String
    let category: Transaction.Category
    let currentAmount: Double
    let suggestedAmount: Double
    let reason: AdjustmentReason
    let confidence: Double // 0.0 to 1.0
    let explanation: String
    let impactDescription: String
    let createdAt: Date
    var isApplied: Bool
    var userResponse: UserResponse?
    
    enum UserResponse: String, Codable {
        case accepted = "Accepted"
        case rejected = "Rejected"
        case modified = "Modified"
        case deferred = "Deferred"
    }
    
    init(category: Transaction.Category, currentAmount: Double, suggestedAmount: Double, reason: AdjustmentReason, confidence: Double, explanation: String, impactDescription: String) {
        self.id = UUID().uuidString
        self.category = category
        self.currentAmount = currentAmount
        self.suggestedAmount = suggestedAmount
        self.reason = reason
        self.confidence = confidence
        self.explanation = explanation
        self.impactDescription = impactDescription
        self.createdAt = Date()
        self.isApplied = false
        self.userResponse = nil
    }
    
    var adjustmentAmount: Double {
        return suggestedAmount - currentAmount
    }
    
    var adjustmentPercentage: Double {
        guard currentAmount > 0 else { return 0 }
        return (adjustmentAmount / currentAmount) * 100
    }
    
    var isIncrease: Bool {
        return adjustmentAmount > 0
    }
    
    var urgencyLevel: UrgencyLevel {
        if confidence > 0.8 && abs(adjustmentPercentage) > 20 {
            return .high
        } else if confidence > 0.6 && abs(adjustmentPercentage) > 10 {
            return .medium
        } else {
            return .low
        }
    }
    
    enum UrgencyLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}

// MARK: - AI Budget Adjuster

@MainActor
class BudgetAdjuster: ObservableObject {
    @Published var pendingAdjustments: [BudgetAdjustment] = []
    @Published var adjustmentHistory: [BudgetAdjustment] = []
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    
    private let transactionStore: TransactionStore
    private let userStore: UserStore
    
    init(transactionStore: TransactionStore, userStore: UserStore) {
        self.transactionStore = transactionStore
        self.userStore = userStore
        startPeriodicAnalysis()
    }
    
    // MARK: - AI Analysis Engine
    
    func analyzeAndSuggestAdjustments() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let currentBudgets = transactionStore.budgets
        let recentTransactions = getRecentTransactions()
        let spendingPatterns = analyzeSpendingPatterns()
        
        var newAdjustments: [BudgetAdjustment] = []
        
        // 1. Check for overspending
        newAdjustments.append(contentsOf: detectOverspending(budgets: currentBudgets, transactions: recentTransactions))
        
        // 2. Identify underspending opportunities
        newAdjustments.append(contentsOf: detectUnderspending(budgets: currentBudgets, patterns: spendingPatterns))
        
        // 3. Seasonal adjustments
        newAdjustments.append(contentsOf: suggestSeasonalAdjustments(patterns: spendingPatterns))
        
        // 4. Income-based adjustments
        if let incomeChange = detectIncomeChange() {
            newAdjustments.append(contentsOf: adjustForIncomeChange(incomeChange))
        }
        
        // 5. Emergency fund protection
        newAdjustments.append(contentsOf: protectEmergencyFund())
        
        // Filter out low-confidence suggestions and duplicates
        let filteredAdjustments = newAdjustments
            .filter { $0.confidence > 0.4 }
            .uniqued(by: \.category)
        
        pendingAdjustments = filteredAdjustments
        lastAnalysisDate = Date()
    }
    
    private func detectOverspending(budgets: [Budget], transactions: [Transaction]) -> [BudgetAdjustment] {
        var adjustments: [BudgetAdjustment] = []
        
        for budget in budgets {
            let currentSpent = transactionStore.categoryTotal(for: budget.category)
            let spendingRate = currentSpent / budget.amount
            
            if spendingRate > 0.9 { // 90% of budget used
                let daysInMonth = 30.0
                let daysElapsed = Double(Calendar.current.component(.day, from: Date()))
                let projectedSpending = currentSpent * (daysInMonth / daysElapsed)
                
                if projectedSpending > budget.amount * 1.2 { // Projected 20% overspend
                    let suggestedIncrease = projectedSpending * 1.1 // Add 10% buffer
                    
                    let adjustment = BudgetAdjustment(
                        category: budget.category,
                        currentAmount: budget.amount,
                        suggestedAmount: suggestedIncrease,
                        reason: .overspending,
                        confidence: min(0.9, spendingRate),
                        explanation: "You're on track to exceed your \(budget.category.rawValue) budget by \(Int((projectedSpending / budget.amount - 1) * 100))% this month.",
                        impactDescription: "Increasing this budget will help avoid overspending stress and maintain financial balance."
                    )
                    
                    adjustments.append(adjustment)
                }
            }
        }
        
        return adjustments
    }
    
    private func detectUnderspending(budgets: [Budget], patterns: SpendingPatterns) -> [BudgetAdjustment] {
        var adjustments: [BudgetAdjustment] = []
        
        for budget in budgets {
            let currentSpent = transactionStore.categoryTotal(for: budget.category)
            let spendingRate = currentSpent / budget.amount
            
            if spendingRate < 0.6 && budget.amount > 100 { // Under 60% usage on significant budgets
                let historicalAverage = patterns.averageSpending[budget.category] ?? currentSpent
                let suggestedAmount = max(historicalAverage * 1.1, budget.amount * 0.8)
                
                if suggestedAmount < budget.amount {
                    let adjustment = BudgetAdjustment(
                        category: budget.category,
                        currentAmount: budget.amount,
                        suggestedAmount: suggestedAmount,
                        reason: .underspending,
                        confidence: 0.7,
                        explanation: "You consistently spend less in \(budget.category.rawValue). Consider reallocating \(Int(budget.amount - suggestedAmount)) to other categories or savings.",
                        impactDescription: "Redirecting unused budget allocation can improve your financial efficiency."
                    )
                    
                    adjustments.append(adjustment)
                }
            }
        }
        
        return adjustments
    }
    
    private func suggestSeasonalAdjustments(patterns: SpendingPatterns) -> [BudgetAdjustment] {
        var adjustments: [BudgetAdjustment] = []
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        // Holiday season adjustments (November-December)
        if currentMonth >= 11 || currentMonth <= 1 {
            if let entertainmentBudget = transactionStore.budgets.first(where: { $0.category == .entertainment }) {
                let holidayMultiplier = 1.4 // 40% increase for holiday spending
                let suggestedAmount = entertainmentBudget.amount * holidayMultiplier
                
                let adjustment = BudgetAdjustment(
                    category: .entertainment,
                    currentAmount: entertainmentBudget.amount,
                    suggestedAmount: suggestedAmount,
                    reason: .seasonalTrend,
                    confidence: 0.8,
                    explanation: "Holiday season typically sees 40% higher entertainment and dining expenses.",
                    impactDescription: "Temporarily increasing this budget helps manage holiday spending without stress."
                )
                
                adjustments.append(adjustment)
            }
        }
        
        // Summer adjustments (June-August)
        if currentMonth >= 6 && currentMonth <= 8 {
            if let transportationBudget = transactionStore.budgets.first(where: { $0.category == .transportation }) {
                let summerMultiplier = 1.25 // 25% increase for summer travel
                let suggestedAmount = transportationBudget.amount * summerMultiplier
                
                let adjustment = BudgetAdjustment(
                    category: .transportation,
                    currentAmount: transportationBudget.amount,
                    suggestedAmount: suggestedAmount,
                    reason: .seasonalTrend,
                    confidence: 0.7,
                    explanation: "Summer months often involve increased travel and transportation costs.",
                    impactDescription: "Adjusting for seasonal travel patterns helps maintain budget accuracy."
                )
                
                adjustments.append(adjustment)
            }
        }
        
        return adjustments
    }
    
    private func adjustForIncomeChange(_ incomeChange: IncomeChangeAnalysis) -> [BudgetAdjustment] {
        var adjustments: [BudgetAdjustment] = []
        
        let adjustmentFactor = incomeChange.percentageChange / 100.0
        
        for budget in transactionStore.budgets {
            // Prioritize essential vs. discretionary spending
            let priorityMultiplier: Double
            switch budget.category {
            case .rent, .utilities: priorityMultiplier = 0.5 // Essential - adjust less
            case .groceries: priorityMultiplier = 0.7
            case .entertainment, .other: priorityMultiplier = 1.2 // Discretionary - adjust more
            case .transportation: priorityMultiplier = 0.8
            }
            
            let suggestedAdjustment = budget.amount * adjustmentFactor * priorityMultiplier
            let suggestedAmount = budget.amount + suggestedAdjustment
            
            if abs(suggestedAdjustment) > budget.amount * 0.05 { // Only suggest if change is >5%
                let adjustment = BudgetAdjustment(
                    category: budget.category,
                    currentAmount: budget.amount,
                    suggestedAmount: max(0, suggestedAmount),
                    reason: .incomeChange,
                    confidence: incomeChange.confidence,
                    explanation: "Your income \(incomeChange.percentageChange > 0 ? "increased" : "decreased") by \(abs(Int(incomeChange.percentageChange)))%. Adjusting \(budget.category.rawValue) budget accordingly.",
                    impactDescription: "Keeping budgets aligned with income changes maintains financial balance."
                )
                
                adjustments.append(adjustment)
            }
        }
        
        return adjustments
    }
    
    private func protectEmergencyFund() -> [BudgetAdjustment] {
        var adjustments: [BudgetAdjustment] = []
        
        let totalIncome = transactionStore.totalIncome
        let totalExpenses = transactionStore.totalExpenses
        let currentBalance = totalIncome - totalExpenses
        let recommendedEmergencyFund = totalExpenses * 0.25 // 3 months of expenses (quarterly check)
        
        if currentBalance < recommendedEmergencyFund {
            let shortfall = recommendedEmergencyFund - currentBalance
            
            // Find the highest discretionary budget to reduce
            let discretionaryBudgets = transactionStore.budgets.filter { 
                $0.category == .entertainment || $0.category == .other 
            }.sorted { $0.amount > $1.amount }
            
            if let highestDiscretionary = discretionaryBudgets.first, shortfall > 0 {
                let reductionAmount = min(shortfall, highestDiscretionary.amount * 0.3) // Max 30% reduction
                let suggestedAmount = highestDiscretionary.amount - reductionAmount
                
                let adjustment = BudgetAdjustment(
                    category: highestDiscretionary.category,
                    currentAmount: highestDiscretionary.amount,
                    suggestedAmount: suggestedAmount,
                    reason: .emergencyFund,
                    confidence: 0.8,
                    explanation: "Your emergency fund is below recommended levels. Consider reducing discretionary spending by $\(Int(reductionAmount)).",
                    impactDescription: "Building an emergency fund provides financial security and peace of mind."
                )
                
                adjustments.append(adjustment)
            }
        }
        
        return adjustments
    }
    
    // MARK: - User Actions
    
    func applyAdjustment(_ adjustment: BudgetAdjustment, response: BudgetAdjustment.UserResponse, customAmount: Double? = nil) {
        guard let index = pendingAdjustments.firstIndex(where: { $0.id == adjustment.id }) else { return }
        
        var updatedAdjustment = adjustment
        updatedAdjustment.userResponse = response
        updatedAdjustment.isApplied = true
        
        switch response {
        case .accepted:
            // Apply the suggested budget change
            updateBudget(category: adjustment.category, newAmount: adjustment.suggestedAmount)
            
        case .modified:
            // Apply custom amount if provided
            if let customAmount = customAmount {
                updateBudget(category: adjustment.category, newAmount: customAmount)
            }
            
        case .rejected, .deferred:
            // No action needed for rejected/deferred adjustments
            break
        }
        
        // Move from pending to history
        pendingAdjustments.remove(at: index)
        adjustmentHistory.insert(updatedAdjustment, at: 0)
        
        // Keep only last 50 historical adjustments
        if adjustmentHistory.count > 50 {
            adjustmentHistory = Array(adjustmentHistory.prefix(50))
        }
    }
    
    private func updateBudget(category: Transaction.Category, newAmount: Double) {
        let newBudget = Budget(category: category, amount: newAmount)
        transactionStore.addBudget(newBudget)
    }
    
    // MARK: - Analysis Helpers
    
    private func getRecentTransactions(days: Int = 30) -> [Transaction] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return transactionStore.transactions.filter { $0.date >= cutoffDate }
    }
    
    private func analyzeSpendingPatterns() -> SpendingPatterns {
        let transactions = transactionStore.transactions
        var categoryTotals: [Transaction.Category: Double] = [:]
        
        for category in Transaction.Category.allCases {
            let total = transactions
                .filter { $0.category == category && $0.type == .expense }
                .reduce(0) { $0 + $1.amount }
            categoryTotals[category] = total
        }
        
        return SpendingPatterns(averageSpending: categoryTotals)
    }
    
    private func detectIncomeChange() -> IncomeChangeAnalysis? {
        let allIncome = transactionStore.transactions.filter { $0.type == .income }
        
        // Compare last 30 days vs previous 30 days
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: now) ?? now
        
        let recentIncome = allIncome.filter { $0.date >= thirtyDaysAgo }.reduce(0) { $0 + $1.amount }
        let previousIncome = allIncome.filter { $0.date >= sixtyDaysAgo && $0.date < thirtyDaysAgo }.reduce(0) { $0 + $1.amount }
        
        guard previousIncome > 0 else { return nil }
        
        let percentageChange = ((recentIncome - previousIncome) / previousIncome) * 100
        
        if abs(percentageChange) > 10 { // Only consider significant changes
            return IncomeChangeAnalysis(
                percentageChange: percentageChange,
                confidence: min(0.9, abs(percentageChange) / 50) // Higher confidence for larger changes
            )
        }
        
        return nil
    }
    
    private func startPeriodicAnalysis() {
        // Run analysis every 24 hours
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            Task { @MainActor in
                await self.analyzeAndSuggestAdjustments()
            }
        }
        
        // Run initial analysis after a short delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await analyzeAndSuggestAdjustments()
        }
    }
}

// MARK: - Supporting Types

struct SpendingPatterns {
    let averageSpending: [Transaction.Category: Double]
}

struct IncomeChangeAnalysis {
    let percentageChange: Double
    let confidence: Double
}

// MARK: - Array Extension for Unique Elements

extension Array {
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return self.filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
