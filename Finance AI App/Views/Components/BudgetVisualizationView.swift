import SwiftUI
import Charts

struct BudgetVisualizationView: View {
    @ObservedObject var store: TransactionStore
    @State private var selectedTimeRange: TimeRange = .year
    @State private var selectedCategory: Transaction.Category?
    
    var body: some View {
        VStack(spacing: 20) {
            // Time range selector
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Budget progress chart
            VStack(alignment: .leading, spacing: 10) {
                Text("Budget Progress")
                    .font(.headline)
                
                Chart {
                    ForEach(store.budgets) { budget in
                        BarMark(
                            x: .value("Category", budget.category.rawValue),
                            y: .value("Budget", budget.amount)
                        )
                        .foregroundStyle(Color.blue.opacity(0.3))
                        
                        BarMark(
                            x: .value("Category", budget.category.rawValue),
                            y: .value("Spent", store.categoryTotal(for: budget.category))
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // Category breakdown
            VStack(alignment: .leading, spacing: 10) {
                Text("Category Breakdown")
                    .font(.headline)
                
                Chart {
                    ForEach(store.budgets) { budget in
                        SectorMark(
                            angle: .value("Spent", store.categoryTotal(for: budget.category)),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", budget.category.rawValue))
                        .annotation(position: .overlay) {
                            Text("\(Int((store.categoryTotal(for: budget.category) / budget.amount) * 100))%")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 200)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // Spending trends
            VStack(alignment: .leading, spacing: 10) {
                Text("Spending Trends")
                    .font(.headline)
                
                Chart {
                    ForEach(store.getSpendingTrends()) { insight in
                        LineMark(
                            x: .value("Category", insight.category.rawValue),
                            y: .value("Change", insight.percentageChange)
                        )
                        .foregroundStyle(by: .value("Category", insight.category.rawValue))
                        
                        PointMark(
                            x: .value("Category", insight.category.rawValue),
                            y: .value("Change", insight.percentageChange)
                        )
                        .foregroundStyle(by: .value("Category", insight.category.rawValue))
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .padding()
    }
}

#Preview {
    BudgetVisualizationView(store: TransactionStore())
} 