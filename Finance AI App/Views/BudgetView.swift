import SwiftUI

struct BudgetView: View {
    @ObservedObject var store: TransactionStore
    @State private var showingAddBudget = false
    @State private var selectedCategory: Transaction.Category = .other
    @State private var budgetAmount = ""
    @State private var alertThreshold = 0.8
    
    var body: some View {
        List {
            // Budget Alerts Section
            if !store.alerts.isEmpty {
                Section("Alerts") {
                    ForEach(store.alerts) { alert in
                        HStack {
                            Image(systemName: alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(alert.severity == .critical ? .red : .yellow)
                            Text(alert.message)
                                .foregroundColor(alert.severity == .critical ? .red : .primary)
                        }
                    }
                }
            }
            
            // Budgets Section
            Section("Category Budgets") {
                ForEach(store.budgets) { budget in
                    BudgetRow(budget: budget, spent: store.categoryTotal(for: budget.category))
                }
                
                Button(action: { showingAddBudget = true }) {
                    Label("Add Budget", systemImage: "plus.circle.fill")
                }
            }
            
            // Insights Section
            Section("Spending Insights") {
                ForEach(store.getSpendingTrends()) { insight in
                    SpendingInsightRow(insight: insight)
                }
            }
            
            // Suggestions Section
            Section("Smart Suggestions") {
                ForEach(store.generateSuggestions()) { suggestion in
                    SuggestionRow(suggestion: suggestion)
                }
            }
        }
        .navigationTitle("Budgets & Insights")
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetView(store: store)
        }
    }
}

struct BudgetRow: View {
    let budget: Budget
    let spent: Double
    
    private var percentageSpent: Double {
        spent / budget.amount
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(budget.category.rawValue)
                    .font(.headline)
                Spacer()
                Text("$\(String(format: "%.2f", spent)) / $\(String(format: "%.2f", budget.amount))")
                    .foregroundColor(percentageSpent > 1 ? .red : .primary)
            }
            
            ProgressView(value: min(percentageSpent, 1.0))
                .tint(percentageSpent > budget.alertThreshold ? 
                      (percentageSpent > 1 ? .red : .yellow) : .blue)
        }
    }
}

struct SpendingInsightRow: View {
    let insight: SpendingInsight
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(insight.category.rawValue)
                .font(.headline)
            HStack {
                Text("$\(String(format: "%.2f", insight.currentAmount))")
                Image(systemName: insight.percentageChange > 0 ? "arrow.up.right" : "arrow.down.right")
                Text("\(String(format: "%.1f", abs(insight.percentageChange)))%")
                    .foregroundColor(insight.percentageChange > 0 ? .red : .green)
                Text("vs last month")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SuggestionRow: View {
    let suggestion: FinancialSuggestion
    
    var body: some View {
        HStack {
            Image(systemName: suggestionIcon)
                .foregroundColor(.blue)
            Text(suggestion.message)
        }
    }
    
    private var suggestionIcon: String {
        switch suggestion.type {
        case .subscription: return "repeat.circle"
        case .budgetOptimization: return "chart.pie"
        case .saving: return "dollarsign.circle"
        }
    }
} 