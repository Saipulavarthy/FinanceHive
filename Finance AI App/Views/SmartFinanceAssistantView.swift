import SwiftUI
import Charts

struct SmartFinanceAssistantView: View {
    @ObservedObject var budgetAdjuster: BudgetAdjuster
    @ObservedObject var reminderManager: SmartReminderManager
    @ObservedObject var userStore: UserStore
    @State private var selectedTab = 0
    @State private var showingAdjustmentDetail: BudgetAdjustment?
    @State private var showingReminderDetail: SmartReminder?
    @State private var showingNewReminder = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with AI status
                    aiStatusHeader
                    
                    // Tab Selection
                    Picker("View", selection: $selectedTab) {
                        Text("Budget AI").tag(0)
                        Text("Reminders").tag(1)
                        Text("Insights").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        BudgetAITabView(budgetAdjuster: budgetAdjuster, showingDetail: $showingAdjustmentDetail)
                            .tag(0)
                        
                        RemindersTabView(reminderManager: reminderManager, showingDetail: $showingReminderDetail)
                            .tag(1)
                        
                        InsightsTabView(budgetAdjuster: budgetAdjuster, reminderManager: reminderManager)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingNewReminder = true }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(item: $showingAdjustmentDetail) { adjustment in
                BudgetAdjustmentDetailView(adjustment: adjustment, budgetAdjuster: budgetAdjuster)
            }
            .sheet(item: $showingReminderDetail) { reminder in
                ReminderDetailView(reminder: reminder, reminderManager: reminderManager)
            }
            .sheet(isPresented: $showingNewReminder) {
                CreateReminderView(reminderManager: reminderManager)
            }
        }
    }
    
    private var aiStatusHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Financial Assistant")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        Label("\(budgetAdjuster.pendingAdjustments.count) suggestions", systemImage: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Label("\(reminderManager.overDueReminders.count) overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        if budgetAdjuster.isAnalyzing || reminderManager.isAnalyzing {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Analyzing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if let lastAnalysis = budgetAdjuster.lastAnalysisDate {
                            Text("Updated \(timeAgo(lastAnalysis))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            .shadow(radius: 2)
            .padding(.horizontal)
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Budget AI Tab

struct BudgetAITabView: View {
    @ObservedObject var budgetAdjuster: BudgetAdjuster
    @Binding var showingDetail: BudgetAdjustment?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if budgetAdjuster.pendingAdjustments.isEmpty {
                    EmptyBudgetAIView(budgetAdjuster: budgetAdjuster)
                } else {
                    ForEach(budgetAdjuster.pendingAdjustments.sorted { $0.urgencyLevel.rawValue < $1.urgencyLevel.rawValue }) { adjustment in
                        BudgetAdjustmentCard(adjustment: adjustment) {
                            showingDetail = adjustment
                        }
                    }
                }
                
                // Recent Adjustments History
                if !budgetAdjuster.adjustmentHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Adjustments")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(budgetAdjuster.adjustmentHistory.prefix(3)) { adjustment in
                            HistoryAdjustmentCard(adjustment: adjustment)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Reminders Tab

struct RemindersTabView: View {
    @ObservedObject var reminderManager: SmartReminderManager
    @Binding var showingDetail: SmartReminder?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Overdue Reminders
                if !reminderManager.overDueReminders.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overdue")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                        
                        ForEach(reminderManager.overDueReminders) { reminder in
                            ReminderCard(reminder: reminder, isOverdue: true) {
                                showingDetail = reminder
                            }
                        }
                    }
                }
                
                // Active Reminders
                let activeReminders = reminderManager.activeReminders
                if !activeReminders.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(activeReminders) { reminder in
                            ReminderCard(reminder: reminder) {
                                showingDetail = reminder
                            }
                        }
                    }
                } else if reminderManager.overDueReminders.isEmpty {
                    EmptyRemindersView()
                }
            }
            .padding()
        }
    }
}

// MARK: - Insights Tab

struct InsightsTabView: View {
    @ObservedObject var budgetAdjuster: BudgetAdjuster
    @ObservedObject var reminderManager: SmartReminderManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // AI Performance Metrics
                AIPerformanceCard(budgetAdjuster: budgetAdjuster, reminderManager: reminderManager)
                
                // Adjustment Impact Chart
                if !budgetAdjuster.adjustmentHistory.isEmpty {
                    AdjustmentImpactChart(adjustments: budgetAdjuster.adjustmentHistory)
                }
                
                // Reminder Effectiveness
                ReminderEffectivenessCard(reminderManager: reminderManager)
                
                // Smart Recommendations
                SmartRecommendationsCard(budgetAdjuster: budgetAdjuster, reminderManager: reminderManager)
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct BudgetAdjustmentCard: View {
    let adjustment: BudgetAdjustment
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: adjustment.reason.icon)
                        .font(.title2)
                        .foregroundColor(adjustment.reason.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(adjustment.category.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(adjustment.reason.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(adjustment.isIncrease ? "+" : "-")$\(String(format: "%.0f", abs(adjustment.adjustmentAmount)))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(adjustment.isIncrease ? .red : .green)
                        
                        Text("\(Int(abs(adjustment.adjustmentPercentage)))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(adjustment.explanation)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(adjustment.urgencyLevel.color)
                            .frame(width: 8, height: 8)
                        Text(adjustment.urgencyLevel.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text("Confidence: \(Int(adjustment.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReminderCard: View {
    let reminder: SmartReminder
    var isOverdue: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: reminder.type.icon)
                    .font(.title2)
                    .foregroundColor(reminder.type.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let amount = reminder.amount {
                        Text(reminder.formattedAmount)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(reminder.message)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(reminder.urgencyLevel.color)
                            .frame(width: 8, height: 8)
                        Text(reminder.urgencyLevel.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    if isOverdue {
                        Text("\(abs(reminder.daysUntilDue)) days overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    } else {
                        Text("in \(reminder.daysUntilDue) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isOverdue ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyBudgetAIView: View {
    @ObservedObject var budgetAdjuster: BudgetAdjuster
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("AI Budget Optimizer")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your AI assistant is analyzing your spending patterns. Budget optimization suggestions will appear here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Analyze Now") {
                Task {
                    await budgetAdjuster.analyzeAndSuggestAdjustments()
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.purple)
            .cornerRadius(12)
        }
        .padding(.top, 40)
    }
}

struct EmptyRemindersView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Smart Reminders")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your AI assistant will learn your patterns and automatically create helpful reminders for bills, subscriptions, and savings goals.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 40)
    }
}

struct HistoryAdjustmentCard: View {
    let adjustment: BudgetAdjustment
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: adjustment.userResponse == .accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(adjustment.userResponse == .accepted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(adjustment.category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(adjustment.reason.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(adjustment.isIncrease ? "+" : "-")$\(String(format: "%.0f", abs(adjustment.adjustmentAmount)))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(adjustment.userResponse?.rawValue ?? "Pending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct AIPerformanceCard: View {
    @ObservedObject var budgetAdjuster: BudgetAdjuster
    @ObservedObject var reminderManager: SmartReminderManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Performance")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                MetricCard(title: "Suggestions", value: "\(budgetAdjuster.pendingAdjustments.count)", color: .blue)
                MetricCard(title: "Accepted", value: "\(acceptedAdjustments)", color: .green)
                MetricCard(title: "Accuracy", value: "\(Int(accuracyRate * 100))%", color: .purple)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var acceptedAdjustments: Int {
        budgetAdjuster.adjustmentHistory.filter { $0.userResponse == .accepted }.count
    }
    
    private var accuracyRate: Double {
        let total = budgetAdjuster.adjustmentHistory.count
        guard total > 0 else { return 0 }
        return Double(acceptedAdjustments) / Double(total)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AdjustmentImpactChart: View {
    let adjustments: [BudgetAdjustment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adjustment Impact")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(adjustments.prefix(10)) { adjustment in
                BarMark(
                    x: .value("Amount", abs(adjustment.adjustmentAmount)),
                    y: .value("Category", adjustment.category.rawValue)
                )
                .foregroundStyle(adjustment.isIncrease ? Color.red.gradient : Color.green.gradient)
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct ReminderEffectivenessCard: View {
    @ObservedObject var reminderManager: SmartReminderManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminder Effectiveness")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                MetricCard(title: "Active", value: "\(reminderManager.activeReminders.count)", color: .blue)
                MetricCard(title: "Overdue", value: "\(reminderManager.overDueReminders.count)", color: .red)
                MetricCard(title: "AI Generated", value: "\(aiGeneratedCount)", color: .purple)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var aiGeneratedCount: Int {
        reminderManager.reminders.filter { $0.suggestedByAI }.count
    }
}

struct SmartRecommendationsCard: View {
    @ObservedObject var budgetAdjuster: BudgetAdjuster
    @ObservedObject var reminderManager: SmartReminderManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart Recommendations")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if budgetAdjuster.pendingAdjustments.count > 3 {
                    RecommendationRow(
                        icon: "lightbulb.fill",
                        color: .orange,
                        text: "You have \(budgetAdjuster.pendingAdjustments.count) budget optimizations pending. Review them to improve your financial health."
                    )
                }
                
                if reminderManager.overDueReminders.count > 0 {
                    RecommendationRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        text: "Complete your overdue financial tasks to avoid late fees and maintain good financial habits."
                    )
                }
                
                RecommendationRow(
                    icon: "brain.head.profile",
                    color: .purple,
                    text: "Your AI assistant learns from your behavior. The more you use it, the better it becomes at helping you."
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct RecommendationRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SmartFinanceAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        SmartFinanceAssistantView(
            budgetAdjuster: BudgetAdjuster(transactionStore: TransactionStore(), userStore: UserStore()),
            reminderManager: SmartReminderManager(transactionStore: TransactionStore(), userStore: UserStore()),
            userStore: UserStore()
        )
    }
}
