import SwiftUI
import CoreData

enum RepeatInterval: String, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    var id: String { self.rawValue }
}

struct NewExpenseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    @State private var amount = ""
    @State private var category: Transaction.Category = .other
    @State private var note = ""
    @State private var date = Date()
    @State private var isRecurring = false
    @State private var repeatInterval: RepeatInterval = .monthly
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Amount")) {
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(Transaction.Category.allCases, id: \..self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("Note")) {
                    TextField("Optional note", text: $note)
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Select date", selection: $date, displayedComponents: .date)
                }
                
                Section {
                    Toggle("Recurring Expense", isOn: $isRecurring)
                    if isRecurring {
                        Picker("Repeat Interval", selection: $repeatInterval) {
                            ForEach(RepeatInterval.allCases) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section {
                    Button(action: saveExpense) {
                        HStack {
                            Spacer()
                            Text("Save Expense")
                                .bold()
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { isPresented = false })
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "Please enter a valid amount."
            showingAlert = true
            return
        }
        if isRecurring {
            let recurringExpense = RecurringExpense(context: viewContext)
            recurringExpense.amount = amountValue
            recurringExpense.category = category.rawValue
            recurringExpense.note = note
            recurringExpense.date = date
            recurringExpense.isRecurring = true
            recurringExpense.repeatInterval = repeatInterval.rawValue
            do {
                try viewContext.save()
                isPresented = false
            } catch {
                alertMessage = "Failed to save recurring expense."
                showingAlert = true
            }
        } else {
            // Save as a regular expense (if you have a Core Data Expense entity, otherwise handle as before)
            // Example:
            // let expense = Expense(context: viewContext)
            // expense.amount = amountValue
            // expense.category = category.rawValue
            // expense.note = note
            // expense.date = date
            // try? viewContext.save()
            isPresented = false
        }
        // Reset form (optional)
        amount = ""
        category = .other
        note = ""
        date = Date()
        isRecurring = false
        repeatInterval = .monthly
    }
}

#Preview {
    NewExpenseView(isPresented: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 