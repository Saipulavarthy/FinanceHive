import SwiftUI
import Charts

struct BudgetAdjustmentDetailView: View {
    let adjustment: BudgetAdjustment
    @ObservedObject var budgetAdjuster: BudgetAdjuster
    @Environment(\.dismiss) private var dismiss
    
    @State private var customAmount = ""
    @State private var selectedResponse: BudgetAdjustment.UserResponse = .accepted
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    adjustmentHeader
                    
                    // Impact Analysis
                    impactAnalysisSection
                    
                    // AI Reasoning
                    reasoningSection
                    
                    // Action Buttons
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Budget Adjustment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .alert("Confirm Action", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm") {
                    applyAdjustment()
                }
            } message: {
                Text("Are you sure you want to \(selectedResponse.rawValue.lowercased()) this budget adjustment?")
            }
        }
    }
    
    private var adjustmentHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: adjustment.reason.icon)
                    .font(.system(size: 40))
                    .foregroundColor(adjustment.reason.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(adjustment.category.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(adjustment.reason.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.0f", adjustment.currentAmount))")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text("Suggested")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.0f", adjustment.suggestedAmount))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(adjustment.isIncrease ? .red : .green)
                }
                
                VStack(spacing: 8) {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(adjustment.isIncrease ? "+" : "-")$\(String(format: "%.0f", abs(adjustment.adjustmentAmount)))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(adjustment.isIncrease ? .red : .green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var impactAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Impact Analysis")
                .font(.headline)
            
            VStack(spacing: 12) {
                ImpactRow(
                    title: "Percentage Change",
                    value: "\(Int(abs(adjustment.adjustmentPercentage)))%",
                    color: adjustment.isIncrease ? .red : .green
                )
                
                ImpactRow(
                    title: "Urgency Level",
                    value: adjustment.urgencyLevel.rawValue,
                    color: adjustment.urgencyLevel.color
                )
                
                ImpactRow(
                    title: "AI Confidence",
                    value: "\(Int(adjustment.confidence * 100))%",
                    color: confidenceColor
                )
            }
            
            Text(adjustment.impactDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var reasoningSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Reasoning")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Why this adjustment?", systemImage: "questionmark.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(adjustment.explanation)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if adjustment.reason == .overspending {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Spending Pattern", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Your spending in this category has increased significantly. Adjusting the budget will help maintain financial balance.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                
                if adjustment.reason == .seasonalTrend {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Seasonal Insight", systemImage: "calendar.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Historical data shows spending typically increases during this period. This adjustment accounts for seasonal patterns.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            Text("Your Decision")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Response Selection
                Picker("Response", selection: $selectedResponse) {
                    ForEach([BudgetAdjustment.UserResponse.accepted, .rejected, .modified], id: \.self) { response in
                        Text(response.rawValue).tag(response)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Custom Amount for Modified Response
                if selectedResponse == .modified {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Amount")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text("$")
                                .foregroundColor(.secondary)
                            TextField("Enter amount", text: $customAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                
                // Action Button
                Button(action: { showingConfirmation = true }) {
                    HStack {
                        Image(systemName: iconForResponse)
                        Text(buttonTextForResponse)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colorForResponse)
                    .cornerRadius(16)
                }
                .disabled(selectedResponse == .modified && customAmount.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var confidenceColor: Color {
        if adjustment.confidence > 0.8 { return .green }
        if adjustment.confidence > 0.6 { return .orange }
        return .red
    }
    
    private var iconForResponse: String {
        switch selectedResponse {
        case .accepted: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deferred: return "clock.circle.fill"
        }
    }
    
    private var buttonTextForResponse: String {
        switch selectedResponse {
        case .accepted: return "Accept Adjustment"
        case .rejected: return "Reject Adjustment"
        case .modified: return "Apply Custom Amount"
        case .deferred: return "Defer Decision"
        }
    }
    
    private var colorForResponse: Color {
        switch selectedResponse {
        case .accepted: return .green
        case .rejected: return .red
        case .modified: return .blue
        case .deferred: return .orange
        }
    }
    
    private func applyAdjustment() {
        var customAmountValue: Double? = nil
        
        if selectedResponse == .modified, let amount = Double(customAmount) {
            customAmountValue = amount
        }
        
        budgetAdjuster.applyAdjustment(adjustment, response: selectedResponse, customAmount: customAmountValue)
        dismiss()
    }
}

struct ImpactRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

struct BudgetAdjustmentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetAdjustmentDetailView(
            adjustment: BudgetAdjustment(
                category: .groceries,
                currentAmount: 500,
                suggestedAmount: 600,
                reason: .overspending,
                confidence: 0.85,
                explanation: "You're spending 20% more on groceries this month compared to your budget.",
                impactDescription: "Increasing this budget will help avoid overspending stress."
            ),
            budgetAdjuster: BudgetAdjuster(transactionStore: TransactionStore(), userStore: UserStore())
        )
    }
}
