import SwiftUI
import Charts

struct GroupWalletView: View {
    @StateObject private var sharedWalletStore = SharedWalletStore()
    @ObservedObject var userStore: UserStore
    @State private var showingCreateWallet = false
    @State private var showingAddExpense = false
    @State private var showingAddMember = false
    @State private var showingSettlement = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if let currentWallet = sharedWalletStore.currentWallet {
                    VStack(spacing: 0) {
                        // Wallet Header
                        walletHeaderView(currentWallet)
                        
                        // Tab Selection
                        Picker("View", selection: $selectedTab) {
                            Text("Overview").tag(0)
                            Text("Expenses").tag(1)
                            Text("Balances").tag(2)
                            Text("Members").tag(3)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.bottom)
                        
                        // Tab Content
                        TabView(selection: $selectedTab) {
                            OverviewTabView(wallet: currentWallet, store: sharedWalletStore)
                                .tag(0)
                            
                            ExpensesTabView(wallet: currentWallet, store: sharedWalletStore)
                                .tag(1)
                            
                            BalancesTabView(wallet: currentWallet, store: sharedWalletStore)
                                .tag(2)
                            
                            MembersTabView(wallet: currentWallet, store: sharedWalletStore)
                                .tag(3)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    }
                } else {
                    EmptyWalletView(showingCreateWallet: $showingCreateWallet)
                }
            }
            .navigationTitle("Group Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if sharedWalletStore.currentWallet != nil {
                        Menu {
                            Button(action: { showingAddExpense = true }) {
                                Label("Add Expense", systemImage: "plus.circle")
                            }
                            
                            Button(action: { showingAddMember = true }) {
                                Label("Add Member", systemImage: "person.badge.plus")
                            }
                            
                            Button(action: { showingSettlement = true }) {
                                Label("Record Payment", systemImage: "dollarsign.circle")
                            }
                            
                            Divider()
                            
                            Button(action: { showingCreateWallet = true }) {
                                Label("New Wallet", systemImage: "wallet.pass")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCreateWallet) {
                CreateWalletView(store: sharedWalletStore, userStore: userStore)
            }
            .sheet(isPresented: $showingAddExpense) {
                if let wallet = sharedWalletStore.currentWallet {
                    AddSharedExpenseView(wallet: wallet, store: sharedWalletStore)
                }
            }
            .sheet(isPresented: $showingAddMember) {
                if let wallet = sharedWalletStore.currentWallet {
                    AddMemberView(wallet: wallet, store: sharedWalletStore)
                }
            }
            .sheet(isPresented: $showingSettlement) {
                if let wallet = sharedWalletStore.currentWallet {
                    RecordSettlementView(wallet: wallet, store: sharedWalletStore)
                }
            }
        }
    }
    
    private func walletHeaderView(_ wallet: SharedWallet) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wallet.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let description = wallet.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        Label("\(wallet.activeMemberCount)", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let lastSync = sharedWalletStore.lastSyncTime {
                            Label("Synced \(timeAgo(lastSync))", systemImage: "arrow.clockwise")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", wallet.totalExpenses))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Total Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if wallet.unsettledAmount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("$\(String(format: "%.2f", wallet.unsettledAmount)) unsettled")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Overview Tab

struct OverviewTabView: View {
    let wallet: SharedWallet
    let store: SharedWalletStore
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Quick Stats
                HStack(spacing: 16) {
                    GroupStatCard(title: "Total Expenses", value: "$\(String(format: "%.0f", wallet.totalExpenses))", color: .blue)
                    GroupStatCard(title: "This Month", value: "$\(String(format: "%.0f", currentMonthExpenses))", color: .green)
                }
                
                // Spending by Category Chart
                if !wallet.expenses.isEmpty {
                    CategoryChartView(wallet: wallet)
                }
                
                // Recent Activity
                RecentActivityView(wallet: wallet)
                
                // Outstanding Balances
                OutstandingBalancesView(wallet: wallet)
            }
            .padding()
        }
    }
    
    private var currentMonthExpenses: Double {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        return wallet.expenses.filter { expense in
            let expenseMonth = calendar.component(.month, from: expense.date)
            let expenseYear = calendar.component(.year, from: expense.date)
            return expenseMonth == currentMonth && expenseYear == currentYear
        }.reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Expenses Tab

struct ExpensesTabView: View {
    let wallet: SharedWallet
    let store: SharedWalletStore
    
    var body: some View {
        List {
            ForEach(wallet.expenses.sorted { $0.date > $1.date }) { expense in
                ExpenseRowView(expense: expense, wallet: wallet, store: store)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Balances Tab

struct BalancesTabView: View {
    let wallet: SharedWallet
    let store: SharedWalletStore
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Simplified Debts
                let debts = wallet.getSimplifiedDebts()
                
                if debts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("All Settled Up!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("No outstanding balances")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(debts.indices, id: \.self) { index in
                        let debt = debts[index]
                        DebtRowView(debt: debt, store: store, wallet: wallet)
                    }
                }
                
                Divider()
                    .padding(.vertical)
                
                // Settlement History
                if !wallet.settlements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Payments")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(wallet.settlements.sorted { $0.date > $1.date }.prefix(5), id: \.id) { settlement in
                            SettlementRowView(settlement: settlement, wallet: wallet)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Members Tab

struct MembersTabView: View {
    let wallet: SharedWallet
    let store: SharedWalletStore
    
    var body: some View {
        List {
            ForEach(wallet.members.filter { $0.isActive }) { member in
                MemberRowView(member: member, wallet: wallet)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Supporting Views

struct GroupStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct EmptyWalletView: View {
    @Binding var showingCreateWallet: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Create Your First Group Wallet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start tracking shared expenses with roommates, family, or friends")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingCreateWallet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Wallet")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct GroupWalletView_Previews: PreviewProvider {
    static var previews: some View {
        GroupWalletView(userStore: UserStore())
    }
}
