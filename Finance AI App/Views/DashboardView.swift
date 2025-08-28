import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var store: TransactionStore
    @ObservedObject var userStore: UserStore
    @ObservedObject var achievementsStore: AchievementsStore
    let userName: String
    @State private var selectedTimeFrame: TimeFrame = .month
    @State private var showingBudgetSheet = false
    @State private var showingAddTransactionSheet = false
    @State private var newTransactionType: Transaction.TransactionType = .expense
    @State private var showingAddExpenseSheet = false
    @State private var showingScanReceiptSheet = false
    @State private var showingVoiceExpenseSheet = false
    @State private var showingAddBudget = false
    @State private var selectedCategory: Transaction.Category = .other
    @State private var budgetAmount = ""
    @State private var alertThreshold = 0.8
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DashboardSummaryView(store: store)
                
                // Welcome header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back, \(userName)!")
                        .font(.title)
                        .bold()
                    
                    Text("Here's your financial overview")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // Quick stats
                HStack(spacing: 15) {
                    StatCard(
                        title: "Income",
                        amount: store.totalIncome,
                        icon: "arrow.down.circle.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Expenses",
                        amount: store.totalExpenses,
                        icon: "arrow.up.circle.fill",
                        color: .red
                    )
                    
                    StatCard(
                        title: "Balance",
                        amount: store.totalIncome - store.totalExpenses,
                        icon: "dollarsign.circle.fill",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Quick Actions
                HStack(spacing: 20) {
                    Button(action: { 
                        newTransactionType = .expense
                        showingAddTransactionSheet = true 
                    }) {
                        VStack {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                            Text("Add Expense")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    Button(action: { 
                        newTransactionType = .income
                        showingAddTransactionSheet = true 
                    }) {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            Text("Add Income")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    Button(action: { showingScanReceiptSheet = true }) {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Scan Receipt")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    Button(action: { showingVoiceExpenseSheet = true }) {
                        VStack {
                            Image(systemName: "mic.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                            Text("Voice Entry")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)
                
                // Budget Management Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Budget Management")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAddBudget = true }) {
                            Label("Add Budget", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Budget Alerts
                    if !store.alerts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Alerts")
                                .font(.subheadline)
                                .bold()
                            
                            ForEach(store.alerts) { alert in
                                HStack {
                                    Image(systemName: alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(alert.severity == .critical ? .red : .yellow)
                                    Text(alert.message)
                                        .foregroundColor(alert.severity == .critical ? .red : .primary)
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Budget Progress
                    BudgetProgressView(store: store)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Spending Insights Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Spending Insights")
                        .font(.headline)
                    
                    ForEach(store.getSpendingTrends()) { insight in
                        SpendingInsightRow(insight: insight)
                    }
                    
                    if store.getSpendingTrends().isEmpty {
                        Text("No spending trends available yet. Keep tracking your expenses!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Gamification Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Progress")
                        .font(.headline)
                    
                    HStack {
                        VStack {
                            Text("🔥 \(achievementsStore.expenseTrackingStreak)")
                                .font(.largeTitle)
                                .bold()
                            Text("Day Streak")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        
                        NavigationLink(destination: AchievementsView(store: achievementsStore)) {
                            VStack {
                                Text("🏆 \(achievementsStore.achievements.filter { $0.isUnlocked }.count)")
                                    .font(.largeTitle)
                                    .bold()
                                Text("Badges")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Recent transactions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Transactions")
                        .font(.headline)
                    
                    ForEach(store.transactions.prefix(5)) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    
                    NavigationLink(destination: TransactionListView(store: store)) {
                        Text("View All Transactions")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // AI-powered Tips
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Smart Suggestions")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    if store.generateSuggestions().isEmpty {
                        Text("No suggestions at the moment. Keep tracking your finances!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(store.generateSuggestions().prefix(2)) { suggestion in
                            SuggestionRow(suggestion: suggestion)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarItems(trailing: UserProfileButton(userStore: userStore))
        .sheet(isPresented: $showingBudgetSheet) {
            BudgetManagementView(store: store)
        }
        .sheet(isPresented: $showingAddTransactionSheet) {
            AddTransactionView(store: store, isPresented: $showingAddTransactionSheet, type: newTransactionType)
        }
        .sheet(isPresented: $showingAddExpenseSheet) {
            NewExpenseView(isPresented: $showingAddExpenseSheet)
        }
        .sheet(isPresented: $showingScanReceiptSheet) {
            ScanReceiptView(store: store)
        }
        .sheet(isPresented: $showingVoiceExpenseSheet) {
            VoiceExpenseView(isPresented: $showingVoiceExpenseSheet)
        }
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetView(store: store)
        }
    }
}

// MARK: - Supporting Views

struct HeaderView: View {
    let userName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hey \(userName)! 👋")
                .font(.title)
                .bold()
            
            Text("Here's your financial summary")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct SpendingInsightRow: View {
    let insight: SpendingInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.category.rawValue)
                    .font(.headline)
                Spacer()
                Text("$\(String(format: "%.2f", insight.currentAmount))")
                    .font(.subheadline)
                    .bold()
            }
            
            HStack {
                Image(systemName: insight.percentageChange > 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(insight.percentageChange > 0 ? .red : .green)
                Text("\(String(format: "%.1f", abs(insight.percentageChange)))%")
                    .foregroundColor(insight.percentageChange > 0 ? .red : .green)
                    .font(.subheadline)
                Text("vs last month")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SuggestionRow: View {
    let suggestion: FinancialSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestionIcon)
                    .foregroundColor(.blue)
                Text(suggestion.message)
                    .font(.headline)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var suggestionIcon: String {
        switch suggestion.type {
        case .subscription: return "repeat.circle"
        case .budgetOptimization: return "chart.pie"
        case .saving: return "dollarsign.circle"
        }
    }
}

struct FinancialCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(color)
            
            Text("$\(String(format: "%.2f", amount))")
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.2), radius: 8)
        )
    }
}

struct ExpenseBreakdownCard: View {
    @ObservedObject var store: TransactionStore
    @State private var selectedCategory: Transaction.Category?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Expense Breakdown")
                .font(.headline)
            
            Chart {
                ForEach(Transaction.Category.allCases, id: \.self) { category in
                    let amount = store.categoryTotal(for: category)
                    if amount > 0 {
                        SectorMark(
                            angle: .value("Amount", amount),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", category.rawValue))
                        .opacity(selectedCategory == nil ? 1 : (selectedCategory == category ? 1 : 0.3))
                    }
                }
            }
            .frame(height: 240)
            .chartAngleSelection(value: $selectedCategory)
            .chartLegend(position: .bottom, spacing: 20)
            
            if let selected = selectedCategory {
                let amount = store.categoryTotal(for: selected)
                let total = store.totalExpenses
                let percentage = total > 0 ? (amount / total) * 100 : 0
                
                HStack {
                    Text(selected.rawValue)
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("$\(String(format: "%.2f", amount))")
                            .font(.subheadline)
                        Text("\(String(format: "%.1f", percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .blue.opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
    }
}

struct BudgetProgressCard: View {
    let store: TransactionStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Progress")
                .font(.headline)
            
            ForEach(store.budgets) { budget in
                BudgetProgressRow(
                    category: budget.category,
                    spent: store.categoryTotal(for: budget.category),
                    total: budget.amount
                )
            }
            
            if store.budgets.isEmpty {
                Text("No budgets set")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .blue.opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
    }
}

struct BudgetProgressRow: View {
    let category: Transaction.Category
    let spent: Double
    let total: Double
    
    private var percentage: Double {
        min(spent / total, 1.0)
    }
    
    private var color: Color {
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else {
            return .blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.rawValue)
                Spacer()
                Text("$\(String(format: "%.2f", spent)) / $\(String(format: "%.2f", total))")
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct RecentTransactionsCard: View {
    let store: TransactionStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Transactions")
                .font(.headline)
            
            ForEach(Array(store.transactions.prefix(5))) { transaction in
                TransactionRow(transaction: transaction)
                
                if transaction.id != store.transactions.prefix(5).last?.id {
                    Divider()
                }
            }
            
            if store.transactions.isEmpty {
                Text("No recent transactions")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .blue.opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type == .expense ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(transaction.type == .expense ? .red : .green)
            
            VStack(alignment: .leading) {
                Text(transaction.category.rawValue)
                    .font(.subheadline)
                if let description = transaction.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("$\(String(format: "%.2f", transaction.amount))")
                .font(.subheadline)
                .bold()
                .foregroundColor(transaction.type == .expense ? .red : .green)
        }
        .padding(.vertical, 4)
    }
}

struct UserProfileButton: View {
    @ObservedObject var userStore: UserStore
    @State private var showingProfile = false
    @State private var showingEditProfile = false
    
    var body: some View {
        Button(action: { showingProfile = true }) {
            Image(systemName: "person.circle")
                .font(.title2)
        }
        .sheet(isPresented: $showingProfile) {
            NavigationView {
                List {
                    Section {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(userStore.currentUser?.name ?? "")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(userStore.currentUser?.email ?? "")
                                .foregroundColor(.secondary)
                        }
                    }
                    Section {
                        Button("Edit Profile & Preferences") {
                            showingEditProfile = true
                        }
                    }
                    Section {
                        Toggle("Notifications", isOn: .constant(true))
                    }
                    Section {
                        Button("Sign Out") {
                            userStore.signOut()
                            showingProfile = false
                        }
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("Profile")
                .navigationBarItems(trailing: Button("Done") {
                    showingProfile = false
                })
                .sheet(isPresented: $showingEditProfile) {
                    NavigationView {
                        ProfileEditView(userStore: userStore)
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("$\(String(format: "%.2f", amount))")
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct TransactionListView: View {
    let store: TransactionStore
    var body: some View {
        Text("Transaction List View Placeholder")
    }
}

struct BudgetManagementView: View {
    let store: TransactionStore
    var body: some View {
        Text("Budget Management View Placeholder")
    }
}

struct BudgetProgressView: View {
    @ObservedObject var store: TransactionStore
    
    // Calculate total budget and total spent across all categories
    private var totalBudget: Double {
        store.budgets.reduce(0) { $0 + $1.amount }
    }
    
    private var totalSpent: Double {
        store.budgets.reduce(0) { partialResult, budget in
            partialResult + store.categoryTotal(for: budget.category)
        }
    }
    
    private var progress: Double {
        totalBudget > 0 ? totalSpent / totalBudget : 0
    }
    
    private var progressColor: Color {
        switch progress {
        case 0..<0.5:
            return .green
        case 0.5..<0.9:
            return .yellow
        default:
            return .red
        }
    }
    
    var body: some View {
        VStack {
            if totalBudget > 0 {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20.0)
                        .opacity(0.3)
                        .foregroundColor(progressColor)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(progressColor)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: progress)
                    
                    VStack {
                        Text(String(format: "%.0f %%", min(self.progress, 1.0) * 100.0))
                            .font(.largeTitle)
                            .bold()
                        Text("Spent")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 150, height: 150)
                .padding()
                
                Text("You've spent \(String(format: "%.0f%%", progress * 100)) of your budget this month.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No budgets set. Add a budget to see your progress.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DashboardSummaryView: View {
    @ObservedObject var store: TransactionStore
    
    private var calendar: Calendar { Calendar.current }
    private var currentMonth: Date { calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))! }
    
    // Group expenses by category for the current month
    private var expensesByCategory: [(Transaction.Category, Double)] {
        Transaction.Category.allCases.map { category in
            let total = store.transactions.filter {
                $0.type == .expense &&
                $0.category == category &&
                calendar.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
            }.reduce(0) { $0 + $1.amount }
            return (category, total)
        }
    }
    
    // Total spent this month
    private var totalSpent: Double {
        store.transactions.filter {
            $0.type == .expense &&
            calendar.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
        }.reduce(0) { $0 + $1.amount }
    }
    
    // Total budget for this month (sum of all budgets)
    private var totalBudget: Double {
        store.budgets.reduce(0) { $0 + $1.amount }
    }
    
    // Progress for circular view
    private var progress: Double {
        totalBudget > 0 ? totalSpent / totalBudget : 0
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Total spent label
            Text("Total Spent: $\(String(format: "%.2f", totalSpent))")
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Circular progress view
            ZStack {
                Circle()
                    .stroke(lineWidth: 16)
                    .opacity(0.2)
                    .foregroundColor(.blue)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
                    .foregroundColor(progress < 1.0 ? .blue : .red)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: progress)
                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .bold()
                    Text("of budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            
            // Clean bar chart of expenses by category
            VStack(alignment: .leading, spacing: 16) {
                Text("Spending by Category")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if expensesByCategory.isEmpty {
                    Text("No expenses yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(expensesByCategory.prefix(6), id: \.0) { (category, total) in
                            HStack {
                                // Category name with icon
                                HStack(spacing: 8) {
                                    Image(systemName: categoryIcon(for: category))
                                        .foregroundColor(.blue)
                                        .frame(width: 20)
                                    
                                    Text(shortCategoryName(for: category))
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                }
                                .frame(width: 80, alignment: .leading)
                                
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 8)
                                            .cornerRadius(4)
                                        
                                        Rectangle()
                                            .fill(Color.blue)
                                            .frame(width: geometry.size.width * min(total / maxSpent, 1.0), height: 8)
                                            .cornerRadius(4)
                                    }
                                }
                                .frame(height: 8)
                                
                                // Amount
                                Text("$\(String(format: "%.0f", total))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var maxSpent: Double {
        expensesByCategory.map(\.1).max() ?? 1 // Default to 1 if no expenses
    }
    
    private func categoryIcon(for category: Transaction.Category) -> String {
        switch category {
        case .groceries: return "cart.fill"
        case .transportation: return "car.fill"
        case .rent: return "house.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "film"
        case .other: return "ellipsis.circle"
        }
    }
    
    private func shortCategoryName(for category: Transaction.Category) -> String {
        switch category {
        case .groceries: return "Groceries"
        case .transportation: return "Transport"
        case .rent: return "Rent"
        case .utilities: return "Utilities"
        case .entertainment: return "Entertainment"
        case .other: return "Other"
        }
    }
}

#Preview {
    DashboardView(
        store: TransactionStore(),
        userStore: UserStore(),
        achievementsStore: AchievementsStore(),
        userName: "John"
    )
} 