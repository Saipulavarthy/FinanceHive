import Foundation
import SwiftUI

@MainActor
class SharedWalletStore: ObservableObject {
    @Published var sharedWallets: [SharedWallet] = []
    @Published var currentWallet: SharedWallet?
    @Published var isLoading = false
    @Published var lastSyncTime: Date?
    
    private let userDefaults = UserDefaults.standard
    private let walletsKey = "sharedWallets"
    private let currentWalletKey = "currentWalletId"
    
    init() {
        loadWallets()
        startPeriodicSync()
    }
    
    // MARK: - Wallet Management
    
    func createWallet(name: String, description: String?, currentUser: User) -> SharedWallet {
        let creator = GroupMember(
            name: currentUser.name,
            email: currentUser.email,
            avatarColor: generateRandomColor()
        )
        
        var wallet = SharedWallet(name: name, description: description, createdByMember: creator)
        sharedWallets.append(wallet)
        currentWallet = wallet
        
        saveWallets()
        return wallet
    }
    
    func selectWallet(_ wallet: SharedWallet) {
        currentWallet = wallet
        userDefaults.set(wallet.id, forKey: currentWalletKey)
    }
    
    func deleteWallet(_ wallet: SharedWallet) {
        sharedWallets.removeAll { $0.id == wallet.id }
        if currentWallet?.id == wallet.id {
            currentWallet = sharedWallets.first
        }
        saveWallets()
    }
    
    // MARK: - Member Management
    
    func addMember(to walletId: String, name: String, email: String) {
        guard let index = sharedWallets.firstIndex(where: { $0.id == walletId }) else { return }
        
        let newMember = GroupMember(
            name: name,
            email: email,
            avatarColor: generateRandomColor()
        )
        
        sharedWallets[index].members.append(newMember)
        sharedWallets[index].updateMemberBalances()
        
        if currentWallet?.id == walletId {
            currentWallet = sharedWallets[index]
        }
        
        saveWallets()
        simulateRealTimeSync(message: "\(name) joined the wallet")
    }
    
    func removeMember(from walletId: String, memberId: String) {
        guard let walletIndex = sharedWallets.firstIndex(where: { $0.id == walletId }),
              let memberIndex = sharedWallets[walletIndex].members.firstIndex(where: { $0.id == memberId }) else { return }
        
        let memberName = sharedWallets[walletIndex].members[memberIndex].name
        sharedWallets[walletIndex].members[memberIndex].isActive = false
        sharedWallets[walletIndex].updateMemberBalances()
        
        if currentWallet?.id == walletId {
            currentWallet = sharedWallets[walletIndex]
        }
        
        saveWallets()
        simulateRealTimeSync(message: "\(memberName) left the wallet")
    }
    
    // MARK: - Expense Management
    
    func addExpense(to walletId: String, amount: Double, description: String, category: Transaction.Category, paidByMemberId: String, splitBetween: [String], splitType: SharedExpense.SplitType = .equal, customSplits: [String: Double] = [:]) {
        guard let index = sharedWallets.firstIndex(where: { $0.id == walletId }) else { return }
        
        var expense = SharedExpense(
            amount: amount,
            description: description,
            category: category,
            paidByMemberId: paidByMemberId,
            splitBetween: splitBetween,
            splitType: splitType
        )
        
        if splitType == .custom || splitType == .percentage {
            expense.customSplits = customSplits
        }
        
        sharedWallets[index].expenses.append(expense)
        sharedWallets[index].totalSpent += amount
        sharedWallets[index].updateMemberBalances()
        
        if currentWallet?.id == walletId {
            currentWallet = sharedWallets[index]
        }
        
        saveWallets()
        
        let paidByName = sharedWallets[index].member(withId: paidByMemberId)?.name ?? "Someone"
        simulateRealTimeSync(message: "\(paidByName) added $\(String(format: "%.2f", amount)) expense")
    }
    
    func settleExpense(walletId: String, expenseId: String) {
        guard let walletIndex = sharedWallets.firstIndex(where: { $0.id == walletId }),
              let expenseIndex = sharedWallets[walletIndex].expenses.firstIndex(where: { $0.id == expenseId }) else { return }
        
        sharedWallets[walletIndex].expenses[expenseIndex].isSettled = true
        sharedWallets[walletIndex].updateMemberBalances()
        
        if currentWallet?.id == walletId {
            currentWallet = sharedWallets[walletIndex]
        }
        
        saveWallets()
        simulateRealTimeSync(message: "Expense settled")
    }
    
    // MARK: - Settlement Management
    
    func addSettlement(to walletId: String, fromMemberId: String, toMemberId: String, amount: Double, method: Settlement.PaymentMethod, note: String? = nil) {
        guard let index = sharedWallets.firstIndex(where: { $0.id == walletId }) else { return }
        
        let settlement = Settlement(
            fromMemberId: fromMemberId,
            toMemberId: toMemberId,
            amount: amount,
            method: method,
            note: note
        )
        
        sharedWallets[index].settlements.append(settlement)
        sharedWallets[index].updateMemberBalances()
        
        if currentWallet?.id == walletId {
            currentWallet = sharedWallets[index]
        }
        
        saveWallets()
        
        let fromName = sharedWallets[index].member(withId: fromMemberId)?.name ?? "Someone"
        let toName = sharedWallets[index].member(withId: toMemberId)?.name ?? "Someone"
        simulateRealTimeSync(message: "\(fromName) paid \(toName) $\(String(format: "%.2f", amount))")
    }
    
    func confirmSettlement(walletId: String, settlementId: String) {
        guard let walletIndex = sharedWallets.firstIndex(where: { $0.id == walletId }),
              let settlementIndex = sharedWallets[walletIndex].settlements.firstIndex(where: { $0.id == settlementId }) else { return }
        
        sharedWallets[walletIndex].settlements[settlementIndex].isConfirmed = true
        sharedWallets[walletIndex].updateMemberBalances()
        
        if currentWallet?.id == walletId {
            currentWallet = sharedWallets[walletIndex]
        }
        
        saveWallets()
        simulateRealTimeSync(message: "Payment confirmed")
    }
    
    // MARK: - Data Persistence
    
    private func saveWallets() {
        do {
            let data = try JSONEncoder().encode(sharedWallets)
            userDefaults.set(data, forKey: walletsKey)
        } catch {
            print("Failed to save shared wallets: \(error)")
        }
    }
    
    private func loadWallets() {
        guard let data = userDefaults.data(forKey: walletsKey) else {
            createSampleData()
            return
        }
        
        do {
            sharedWallets = try JSONDecoder().decode([SharedWallet].self, from: data)
            
            // Load current wallet
            if let currentWalletId = userDefaults.string(forKey: currentWalletKey) {
                currentWallet = sharedWallets.first { $0.id == currentWalletId }
            }
            
            if currentWallet == nil && !sharedWallets.isEmpty {
                currentWallet = sharedWallets.first
            }
        } catch {
            print("Failed to load shared wallets: \(error)")
            createSampleData()
        }
    }
    
    // MARK: - Real-time Sync Simulation
    
    private func startPeriodicSync() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                self.performSync()
            }
        }
    }
    
    private func performSync() {
        lastSyncTime = Date()
        // In a real app, this would sync with a server
        // For now, we'll just update the timestamp
    }
    
    private func simulateRealTimeSync(message: String) {
        // Simulate a small delay for real-time effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.lastSyncTime = Date()
            
            // Post notification for real-time updates
            NotificationCenter.default.post(
                name: .sharedWalletUpdated,
                object: nil,
                userInfo: ["message": message, "walletId": self.currentWallet?.id ?? ""]
            )
        }
    }
    
    // MARK: - Utility Functions
    
    private func generateRandomColor() -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow, .teal, .indigo, .mint]
        return colors.randomElement() ?? .blue
    }
    
    private func createSampleData() {
        // Create sample shared wallet for demo
        let sampleUser = GroupMember(name: "You", email: "you@example.com", avatarColor: .blue)
        let roommate1 = GroupMember(name: "Alex", email: "alex@example.com", avatarColor: .green)
        let roommate2 = GroupMember(name: "Jordan", email: "jordan@example.com", avatarColor: .orange)
        
        var sampleWallet = SharedWallet(name: "Apartment Expenses", description: "Shared expenses for our apartment", createdByMember: sampleUser)
        sampleWallet.members.append(contentsOf: [roommate1, roommate2])
        
        // Add sample expenses
        let expense1 = SharedExpense(
            amount: 120.00,
            description: "Grocery shopping",
            category: .groceries,
            paidByMemberId: sampleUser.id,
            splitBetween: [sampleUser.id, roommate1.id, roommate2.id]
        )
        
        let expense2 = SharedExpense(
            amount: 60.00,
            description: "Pizza night",
            category: .entertainment,
            paidByMemberId: roommate1.id,
            splitBetween: [sampleUser.id, roommate1.id, roommate2.id]
        )
        
        sampleWallet.expenses = [expense1, expense2]
        sampleWallet.totalSpent = 180.00
        sampleWallet.updateMemberBalances()
        
        sharedWallets = [sampleWallet]
        currentWallet = sampleWallet
        saveWallets()
    }
    
    // MARK: - Analytics
    
    func getExpensesByCategory(for walletId: String) -> [Transaction.Category: Double] {
        guard let wallet = sharedWallets.first(where: { $0.id == walletId }) else { return [:] }
        
        var categoryTotals: [Transaction.Category: Double] = [:]
        
        for expense in wallet.expenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        return categoryTotals
    }
    
    func getMonthlySpending(for walletId: String) -> [String: Double] {
        guard let wallet = sharedWallets.first(where: { $0.id == walletId }) else { return [:] }
        
        let calendar = Calendar.current
        var monthlyTotals: [String: Double] = [:]
        
        for expense in wallet.expenses {
            let monthYear = calendar.dateComponents([.year, .month], from: expense.date)
            let key = "\(monthYear.year!)-\(String(format: "%02d", monthYear.month!))"
            monthlyTotals[key, default: 0] += expense.amount
        }
        
        return monthlyTotals
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let sharedWalletUpdated = Notification.Name("sharedWalletUpdated")
}
