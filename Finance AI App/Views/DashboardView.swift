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
                        showingAddExpenseSheet = true
                    }) {
                        Label("Add Expense", systemImage: "minus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        newTransactionType = .income
                        showingAddTransactionSheet = true
                    }) {
                        Label("Add Income", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Budget visualization
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Budget Overview")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingBudgetSheet = true }) {
                            Text("Manage Budgets")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    BudgetProgressView(store: store)
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
                        Text("Finbot Tips")
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
                        ForEach(store.generateSuggestions().prefix(1)) { suggestion in
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
            
            // Bar chart of expenses by category
            Chart {
                ForEach(expensesByCategory, id: \..0) { (category, total) in
                    BarMark(
                        x: .value("Category", category.rawValue),
                        y: .value("Spent", total)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxisLabel("Category")
            .chartYAxisLabel("Spent ($)")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
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