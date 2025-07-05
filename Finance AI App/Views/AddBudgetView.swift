import SwiftUI

struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: TransactionStore
    @State private var category: Transaction.Category = .other
    @State private var amount = ""
    @State private var alertThreshold = 0.8
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(Transaction.Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section("Budget Amount") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Text("Alert Threshold")
                        HStack {
                            Slider(value: $alertThreshold, in: 0.5...1.0, step: 0.05)
                            Text("\(Int(alertThreshold * 100))%")
                        }
                    }
                } footer: {
                    Text("You'll receive alerts when spending reaches this percentage of your budget")
                }
            }
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveBudget() {
        guard let amountValue = Double(amount) else {
            alertMessage = "Please enter a valid amount"
            showingAlert = true
            return
        }
        
        let budget = Budget(
            category: category,
            amount: amountValue,
            alertThreshold: alertThreshold
        )
        
        store.addBudget(budget)
        dismiss()
    }
}

#Preview {
    AddBudgetView(store: TransactionStore())
} 