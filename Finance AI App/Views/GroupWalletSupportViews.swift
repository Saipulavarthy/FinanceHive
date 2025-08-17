import SwiftUI
import Charts

// MARK: - Create Wallet View

struct CreateWalletView: View {
    @ObservedObject var store: SharedWalletStore
    @ObservedObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var walletName = ""
    @State private var walletDescription = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Wallet Details")) {
                    TextField("Wallet Name", text: $walletName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (Optional)", text: $walletDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section(footer: Text("You'll be able to invite members after creating the wallet.")) {
                    Button(action: createWallet) {
                        HStack {
                            Image(systemName: "wallet.pass.fill")
                            Text("Create Wallet")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(walletName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Group Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func createWallet() {
        guard let currentUser = userStore.currentUser else {
            alertMessage = "Please sign in to create a wallet."
            showingAlert = true
            return
        }
        
        let trimmedName = walletName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter a wallet name."
            showingAlert = true
            return
        }
        
        let description = walletDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = store.createWallet(
            name: trimmedName,
            description: description.isEmpty ? nil : description,
            currentUser: currentUser
        )
        
        dismiss()
    }
}

// MARK: - Add Member View

struct AddMemberView: View {
    let wallet: SharedWallet
    @ObservedObject var store: SharedWalletStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var memberName = ""
    @State private var memberEmail = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Member Information")) {
                    TextField("Full Name", text: $memberName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Email Address", text: $memberEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                
                Section(footer: Text("The member will be notified via email (in a real app).")) {
                    Button(action: addMember) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Member")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(memberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addMember() {
        let trimmedName = memberName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = memberEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter a name."
            showingAlert = true
            return
        }
        
        // Check if member already exists
        if wallet.members.contains(where: { $0.email.lowercased() == trimmedEmail.lowercased() && $0.isActive }) {
            alertMessage = "A member with this email already exists."
            showingAlert = true
            return
        }
        
        store.addMember(to: wallet.id, name: trimmedName, email: trimmedEmail.isEmpty ? "\(trimmedName.lowercased().replacingOccurrences(of: " ", with: "."))@example.com" : trimmedEmail)
        dismiss()
    }
}

// MARK: - Add Shared Expense View

struct AddSharedExpenseView: View {
    let wallet: SharedWallet
    @ObservedObject var store: SharedWalletStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedCategory: Transaction.Category = .other
    @State private var paidByMemberId: String = ""
    @State private var splitType: SharedExpense.SplitType = .equal
    @State private var selectedMembers: Set<String> = []
    @State private var customSplits: [String: String] = [:]
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Description", text: $description)
                        .textInputAutocapitalization(.sentences)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(Transaction.Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Paid By")) {
                    ForEach(wallet.members.filter { $0.isActive }) { member in
                        HStack {
                            MemberAvatarView(member: member, size: 32)
                            
                            Text(member.name)
                                .font(.body)
                            
                            Spacer()
                            
                            if paidByMemberId == member.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            paidByMemberId = member.id
                        }
                    }
                }
                
                Section(header: Text("Split Type")) {
                    Picker("Split Type", selection: $splitType) {
                        ForEach(SharedExpense.SplitType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Split Between")) {
                    ForEach(wallet.members.filter { $0.isActive }) { member in
                        HStack {
                            MemberAvatarView(member: member, size: 32)
                            
                            VStack(alignment: .leading) {
                                Text(member.name)
                                    .font(.body)
                                
                                if splitType != .equal, selectedMembers.contains(member.id) {
                                    TextField(splitType == .percentage ? "Percentage" : "Amount", text: Binding(
                                        get: { customSplits[member.id] ?? "" },
                                        set: { customSplits[member.id] = $0 }
                                    ))
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                if selectedMembers.contains(member.id) {
                                    selectedMembers.remove(member.id)
                                    customSplits.removeValue(forKey: member.id)
                                } else {
                                    selectedMembers.insert(member.id)
                                }
                            }) {
                                Image(systemName: selectedMembers.contains(member.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedMembers.contains(member.id) ? .blue : .gray)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: addExpense) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Expense")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(amount.isEmpty || description.isEmpty || paidByMemberId.isEmpty || selectedMembers.isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .onAppear {
                // Pre-select all active members
                selectedMembers = Set(wallet.members.filter { $0.isActive }.map { $0.id })
                if paidByMemberId.isEmpty {
                    paidByMemberId = wallet.members.first?.id ?? ""
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "Please enter a valid amount."
            showingAlert = true
            return
        }
        
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else {
            alertMessage = "Please enter a description."
            showingAlert = true
            return
        }
        
        guard !selectedMembers.isEmpty else {
            alertMessage = "Please select at least one member to split with."
            showingAlert = true
            return
        }
        
        // Validate custom splits
        var processedCustomSplits: [String: Double] = [:]
        if splitType != .equal {
            for memberId in selectedMembers {
                guard let splitString = customSplits[memberId], !splitString.isEmpty,
                      let splitValue = Double(splitString), splitValue > 0 else {
                    alertMessage = "Please enter valid split amounts for all selected members."
                    showingAlert = true
                    return
                }
                processedCustomSplits[memberId] = splitValue
            }
            
            // For percentage splits, validate total is 100%
            if splitType == .percentage {
                let totalPercentage = processedCustomSplits.values.reduce(0, +)
                if abs(totalPercentage - 100) > 0.01 {
                    alertMessage = "Percentages must add up to 100%."
                    showingAlert = true
                    return
                }
                // Convert to decimals
                processedCustomSplits = processedCustomSplits.mapValues { $0 / 100 }
            }
        }
        
        store.addExpense(
            to: wallet.id,
            amount: amountValue,
            description: trimmedDescription,
            category: selectedCategory,
            paidByMemberId: paidByMemberId,
            splitBetween: Array(selectedMembers),
            splitType: splitType,
            customSplits: processedCustomSplits
        )
        
        dismiss()
    }
}

// MARK: - Record Settlement View

struct RecordSettlementView: View {
    let wallet: SharedWallet
    @ObservedObject var store: SharedWalletStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var fromMemberId = ""
    @State private var toMemberId = ""
    @State private var amount = ""
    @State private var selectedMethod: Settlement.PaymentMethod = .cash
    @State private var note = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Payment Details")) {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Payment Method", selection: $selectedMethod) {
                        ForEach(Settlement.PaymentMethod.allCases, id: \.self) { method in
                            HStack {
                                Image(systemName: method.icon)
                                Text(method.rawValue)
                            }
                            .tag(method)
                        }
                    }
                    
                    TextField("Note (Optional)", text: $note)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section(header: Text("From (Payer)")) {
                    ForEach(wallet.members.filter { $0.isActive }) { member in
                        HStack {
                            MemberAvatarView(member: member, size: 32)
                            
                            Text(member.name)
                                .font(.body)
                            
                            Spacer()
                            
                            if fromMemberId == member.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            fromMemberId = member.id
                        }
                    }
                }
                
                Section(header: Text("To (Recipient)")) {
                    ForEach(wallet.members.filter { $0.isActive && $0.id != fromMemberId }) { member in
                        HStack {
                            MemberAvatarView(member: member, size: 32)
                            
                            Text(member.name)
                                .font(.body)
                            
                            Spacer()
                            
                            if toMemberId == member.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toMemberId = member.id
                        }
                    }
                }
                
                Section {
                    Button(action: recordSettlement) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                            Text("Record Payment")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(amount.isEmpty || fromMemberId.isEmpty || toMemberId.isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func recordSettlement() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "Please enter a valid amount."
            showingAlert = true
            return
        }
        
        guard fromMemberId != toMemberId else {
            alertMessage = "Please select different members for payer and recipient."
            showingAlert = true
            return
        }
        
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        store.addSettlement(
            to: wallet.id,
            fromMemberId: fromMemberId,
            toMemberId: toMemberId,
            amount: amountValue,
            method: selectedMethod,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        
        store.confirmSettlement(walletId: wallet.id, settlementId: store.sharedWallets.first { $0.id == wallet.id }?.settlements.last?.id ?? "")
        
        dismiss()
    }
}

// MARK: - Supporting Components

struct MemberAvatarView: View {
    let member: GroupMember
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(member.avatarColor)
                .frame(width: size, height: size)
            
            Text(member.initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct ExpenseRowView: View {
    let expense: SharedExpense
    let wallet: SharedWallet
    let store: SharedWalletStore
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(formatDate(expense.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let paidBy = wallet.member(withId: expense.paidByMemberId) {
                    Text("Paid by \(paidBy.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", expense.amount))")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if expense.isSettled {
                    Text("Settled")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DebtRowView: View {
    let debt: (from: GroupMember, to: GroupMember, amount: Double)
    let store: SharedWalletStore
    let wallet: SharedWallet
    
    var body: some View {
        HStack(spacing: 12) {
            MemberAvatarView(member: debt.from, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(debt.from.name) owes \(debt.to.name)")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("$\(String(format: "%.2f", debt.amount))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            MemberAvatarView(member: debt.to, size: 40)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct MemberRowView: View {
    let member: GroupMember
    let wallet: SharedWallet
    
    var body: some View {
        HStack(spacing: 12) {
            MemberAvatarView(member: member, size: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Joined \(formatDate(member.joinedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if member.netBalance > 0 {
                    Text("+$\(String(format: "%.2f", member.netBalance))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("Gets back")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if member.netBalance < 0 {
                    Text("-$\(String(format: "%.2f", abs(member.netBalance)))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Text("Owes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("$0.00")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    Text("Even")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct SettlementRowView: View {
    let settlement: Settlement
    let wallet: SharedWallet
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: settlement.method.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                if let fromMember = wallet.member(withId: settlement.fromMemberId),
                   let toMember = wallet.member(withId: settlement.toMemberId) {
                    Text("\(fromMember.name) → \(toMember.name)")
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text(settlement.method.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(settlement.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("$\(String(format: "%.2f", settlement.amount))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Chart Views

struct CategoryChartView: View {
    let wallet: SharedWallet
    
    private var categoryData: [(category: String, amount: Double)] {
        var categoryTotals: [Transaction.Category: Double] = [:]
        
        for expense in wallet.expenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        return categoryTotals.map { (category: $0.key.rawValue, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(categoryData, id: \.category) { item in
                BarMark(
                    x: .value("Amount", item.amount),
                    y: .value("Category", item.category)
                )
                .foregroundStyle(Color.blue.gradient)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct RecentActivityView: View {
    let wallet: SharedWallet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(wallet.expenses.sorted { $0.date > $1.date }.prefix(3), id: \.id) { expense in
                ExpenseRowView(expense: expense, wallet: wallet, store: SharedWalletStore())
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct OutstandingBalancesView: View {
    let wallet: SharedWallet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outstanding Balances")
                .font(.headline)
                .padding(.horizontal)
            
            let debts = wallet.getSimplifiedDebts()
            
            if debts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All settled up!")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                .padding(.horizontal)
            } else {
                ForEach(debts.prefix(3).indices, id: \.self) { index in
                    let debt = debts[index]
                    HStack {
                        MemberAvatarView(member: debt.from, size: 32)
                        Text("\(debt.from.name) owes \(debt.to.name)")
                            .font(.body)
                        Spacer()
                        Text("$\(String(format: "%.2f", debt.amount))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        MemberAvatarView(member: debt.to, size: 32)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}
