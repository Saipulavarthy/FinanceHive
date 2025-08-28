import SwiftUI
import Charts

struct BudgetVisualizationView: View {
    @ObservedObject var store: TransactionStore
    
    var body: some View {
        VStack(spacing: 20) {
            // Budget Progress Overview
            VStack(alignment: .leading, spacing: 16) {
                Text("Budget Progress")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if store.budgets.isEmpty {
                    Text("No budgets set")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.budgets.prefix(5)) { budget in
                            BudgetProgressRow(
                                category: budget.category,
                                spent: store.categoryTotal(for: budget.category),
                                total: budget.amount
                            )
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Spending Trends
            VStack(alignment: .leading, spacing: 16) {
                Text("Spending Trends")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                let trends = store.getSpendingTrends()
                if trends.isEmpty {
                    Text("No spending data yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(trends.prefix(5)) { insight in
                            SpendingInsightRow(insight: insight)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    BudgetVisualizationView(store: TransactionStore())
} 