import Foundation
import SwiftUI

// MARK: - Group Member Model

struct GroupMember: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var email: String
    var avatarColor: Color
    var joinedAt: Date
    var isActive: Bool
    var totalOwed: Double // Amount this member owes to others
    var totalOwedTo: Double // Amount others owe to this member
    
    init(id: String = UUID().uuidString, name: String, email: String, avatarColor: Color = .blue, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarColor = avatarColor
        self.joinedAt = Date()
        self.isActive = isActive
        self.totalOwed = 0.0
        self.totalOwedTo = 0.0
    }
    
    var netBalance: Double {
        return totalOwedTo - totalOwed
    }
    
    var initials: String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).map { String($0.prefix(1)) }.joined()
        return initials.isEmpty ? "?" : initials.uppercased()
    }
    
    // Simplified Codable conformance - Color will use a string representation
    enum CodingKeys: String, CodingKey {
        case id, name, email, joinedAt, isActive, totalOwed, totalOwedTo, avatarColorName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        totalOwed = try container.decode(Double.self, forKey: .totalOwed)
        totalOwedTo = try container.decode(Double.self, forKey: .totalOwedTo)
        
        // Decode Color from string name
        let colorName = try container.decodeIfPresent(String.self, forKey: .avatarColorName) ?? "blue"
        avatarColor = Self.colorFromName(colorName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(joinedAt, forKey: .joinedAt)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(totalOwed, forKey: .totalOwed)
        try container.encode(totalOwedTo, forKey: .totalOwedTo)
        
        // Encode Color as string name
        try container.encode(Self.nameFromColor(avatarColor), forKey: .avatarColorName)
    }
    
    private static func colorFromName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "yellow": return .yellow
        case "teal": return .teal
        case "indigo": return .indigo
        case "mint": return .mint
        default: return .blue
        }
    }
    
    private static func nameFromColor(_ color: Color) -> String {
        // This is a simplified approach - in a real app you'd want more sophisticated color matching
        return "blue" // Default to blue for simplicity
    }
}

// MARK: - Shared Expense Model

struct SharedExpense: Identifiable, Codable {
    let id: String
    var amount: Double
    var description: String
    var category: Transaction.Category
    var paidByMemberId: String
    var splitBetween: [String] // Member IDs
    var splitType: SplitType
    var customSplits: [String: Double] // Member ID -> Amount (for custom splits)
    var date: Date
    var isSettled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    enum SplitType: String, Codable, CaseIterable {
        case equal = "Equal Split"
        case custom = "Custom Split"
        case percentage = "Percentage Split"
        
        var description: String {
            switch self {
            case .equal: return "Split equally among all members"
            case .custom: return "Custom amounts for each member"
            case .percentage: return "Split by percentage"
            }
        }
    }
    
    init(amount: Double, description: String, category: Transaction.Category, paidByMemberId: String, splitBetween: [String], splitType: SplitType = .equal) {
        self.id = UUID().uuidString
        self.amount = amount
        self.description = description
        self.category = category
        self.paidByMemberId = paidByMemberId
        self.splitBetween = splitBetween
        self.splitType = splitType
        self.customSplits = [:]
        self.date = Date()
        self.isSettled = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func amountPerPerson() -> Double {
        guard !splitBetween.isEmpty else { return 0 }
        
        switch splitType {
        case .equal:
            return amount / Double(splitBetween.count)
        case .custom:
            // For custom splits, return average (for display purposes)
            let totalCustom = customSplits.values.reduce(0, +)
            return totalCustom / Double(splitBetween.count)
        case .percentage:
            // For percentage splits, return average
            return amount / Double(splitBetween.count)
        }
    }
    
    func amountForMember(_ memberId: String) -> Double {
        switch splitType {
        case .equal:
            return splitBetween.contains(memberId) ? amountPerPerson() : 0
        case .custom:
            return customSplits[memberId] ?? 0
        case .percentage:
            // Percentage stored as decimal (0.25 for 25%)
            let percentage = customSplits[memberId] ?? 0
            return amount * percentage
        }
    }
}

// MARK: - Settlement Model

struct Settlement: Identifiable, Codable {
    let id: String
    var fromMemberId: String
    var toMemberId: String
    var amount: Double
    var date: Date
    var method: PaymentMethod
    var note: String?
    var isConfirmed: Bool
    
    enum PaymentMethod: String, Codable, CaseIterable {
        case cash = "Cash"
        case venmo = "Venmo"
        case paypal = "PayPal"
        case zelle = "Zelle"
        case bankTransfer = "Bank Transfer"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .cash: return "banknote"
            case .venmo: return "phone.circle"
            case .paypal: return "creditcard.circle"
            case .zelle: return "dollarsign.circle"
            case .bankTransfer: return "building.columns"
            case .other: return "ellipsis.circle"
            }
        }
    }
    
    init(fromMemberId: String, toMemberId: String, amount: Double, method: PaymentMethod = .cash, note: String? = nil) {
        self.id = UUID().uuidString
        self.fromMemberId = fromMemberId
        self.toMemberId = toMemberId
        self.amount = amount
        self.date = Date()
        self.method = method
        self.note = note
        self.isConfirmed = false
    }
}

// MARK: - Shared Wallet Model

struct SharedWallet: Identifiable, Codable {
    let id: String
    var name: String
    var description: String?
    var members: [GroupMember]
    var expenses: [SharedExpense]
    var settlements: [Settlement]
    var createdAt: Date
    var updatedAt: Date
    var createdByMemberId: String
    var isActive: Bool
    var totalSpent: Double
    var currency: String
    
    init(name: String, description: String? = nil, createdByMember: GroupMember) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.members = [createdByMember]
        self.expenses = []
        self.settlements = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.createdByMemberId = createdByMember.id
        self.isActive = true
        self.totalSpent = 0.0
        self.currency = "USD"
    }
    
    var activeMemberCount: Int {
        members.filter { $0.isActive }.count
    }
    
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var unsettledAmount: Double {
        expenses.filter { !$0.isSettled }.reduce(0) { $0 + $1.amount }
    }
    
    // Calculate debt matrix between members
    func calculateDebts() -> [String: [String: Double]] {
        var debts: [String: [String: Double]] = [:]
        
        // Initialize debt matrix
        for member in members {
            debts[member.id] = [:]
            for otherMember in members {
                if member.id != otherMember.id {
                    debts[member.id]?[otherMember.id] = 0.0
                }
            }
        }
        
        // Calculate debts from expenses
        for expense in expenses.filter({ !$0.isSettled }) {
            let paidBy = expense.paidByMemberId
            
            for memberId in expense.splitBetween {
                if memberId != paidBy {
                    let amountOwed = expense.amountForMember(memberId)
                    let currentAmount = debts[memberId]?[paidBy] ?? 0
                    debts[memberId]?[paidBy] = currentAmount + amountOwed
                }
            }
        }
        
        // Subtract settlements
        for settlement in settlements.filter({ $0.isConfirmed }) {
            let fromId = settlement.fromMemberId
            let toId = settlement.toMemberId
            let currentAmount = debts[fromId]?[toId] ?? 0
            debts[fromId]?[toId] = currentAmount - settlement.amount
        }
        
        return debts
    }
    
    // Get simplified debt settlements (who owes whom)
    func getSimplifiedDebts() -> [(from: GroupMember, to: GroupMember, amount: Double)] {
        let debts = calculateDebts()
        var simplifiedDebts: [(from: GroupMember, to: GroupMember, amount: Double)] = []
        
        for (fromId, toDebts) in debts {
            for (toId, amount) in toDebts {
                if amount > 0.01 { // Avoid tiny amounts
                    if let fromMember = members.first(where: { $0.id == fromId }),
                       let toMember = members.first(where: { $0.id == toId }) {
                        simplifiedDebts.append((from: fromMember, to: toMember, amount: amount))
                    }
                }
            }
        }
        
        return simplifiedDebts.sorted { $0.amount > $1.amount }
    }
    
    // Get member by ID
    func member(withId id: String) -> GroupMember? {
        return members.first { $0.id == id }
    }
    
    // Update member balances
    mutating func updateMemberBalances() {
        let debts = calculateDebts()
        
        for i in members.indices {
            let memberId = members[i].id
            
            // Calculate total owed by this member
            let totalOwed = debts[memberId]?.values.reduce(0, +) ?? 0
            
            // Calculate total owed to this member
            let totalOwedTo = debts.compactMap { (_, toDebts) in
                toDebts[memberId]
            }.reduce(0, +)
            
            members[i].totalOwed = totalOwed
            members[i].totalOwedTo = totalOwedTo
        }
        
        updatedAt = Date()
    }
}
