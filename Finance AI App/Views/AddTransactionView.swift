import SwiftUI

struct AddTransactionView: View {
    @ObservedObject var store: TransactionStore
    @Binding var isPresented: Bool
    
    @State private var amount = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var type: Transaction.TransactionType
    @State private var category: Transaction.Category = .other
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(store: TransactionStore, isPresented: Binding<Bool>, type: Transaction.TransactionType) {
        self.store = store
        self._isPresented = isPresented
        self._type = State(initialValue: type)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction Type") {
                    Picker("Type", selection: $type) {
                        Text("Expense").tag(Transaction.TransactionType.expense)
                        Text("Income").tag(Transaction.TransactionType.income)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Amount") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(Transaction.Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Description (Optional)", text: $description)
                }
                
                Section {
                    Button(action: addTransaction) {
                        HStack {
                            Spacer()
                            Text("Add Transaction")
                                .bold()
                            Spacer()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarItems(leading: Button("Cancel") { isPresented = false })
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addTransaction() {
        guard let amountValue = Double(amount) else {
            alertMessage = "Please enter a valid amount"
            showingAlert = true
            return
        }
        
        let transaction = Transaction(
            type: type,
            amount: amountValue,
            category: category,
            date: date,
            description: description.isEmpty ? nil : description
        )
        
        store.addTransaction(transaction)
        
        // Dismiss sheet
        isPresented = false
        
        // Reset form
        amount = ""
        description = ""
        date = Date()
        type = .expense
        category = .other
    }
}

#Preview {
    NavigationView {
        AddTransactionView(store: TransactionStore(), isPresented: .constant(true), type: .expense)
    }
} 