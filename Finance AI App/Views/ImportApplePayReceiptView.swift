import SwiftUI
import CoreData

struct ImportApplePayReceiptView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var receiptText: String = ""
    @State private var importResult: String? = nil
    @State private var isImporting: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Paste Apple Pay Receipt")) {
                    TextEditor(text: $receiptText)
                        .frame(height: 120)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                Section {
                    Button(action: importReceipt) {
                        HStack {
                            Spacer()
                            if isImporting {
                                ProgressView()
                            } else {
                                Text("Import Receipt").bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(receiptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
                }
                if let result = importResult {
                    Section {
                        Text(result)
                            .foregroundColor(result.contains("successfully") ? .green : .red)
                    }
                }
            }
            .navigationTitle("Import Apple Pay Receipt")
        }
    }
    
    private func importReceipt() {
        isImporting = true
        defer { isImporting = false }
        let pattern = #"\\$([0-9]+(?:\\.[0-9]{2})?)\\s+at\\s+([A-Za-z0-9 &\\-']+)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(receiptText.startIndex..., in: receiptText)
            if let match = regex.firstMatch(in: receiptText, options: [], range: range),
               let amountRange = Range(match.range(at: 1), in: receiptText),
               let merchantRange = Range(match.range(at: 2), in: receiptText) {
                let amountString = String(receiptText[amountRange])
                let merchant = String(receiptText[merchantRange])
                if let amount = Double(amountString) {
                    let expense = RecurringExpense(context: viewContext)
                    expense.amount = amount
                    expense.category = merchant
                    expense.date = Date()
                    expense.isRecurring = false
                    expense.repeatInterval = nil
                    do {
                        try viewContext.save()
                        importResult = "Imported $\(amountString) at \(merchant) successfully!"
                        receiptText = ""
                    } catch {
                        importResult = "Failed to save expense: \(error.localizedDescription)"
                    }
                    return
                }
            }
        }
        importResult = "Could not parse amount and merchant from the receipt. Please check the format."
    }
}

#Preview {
    ImportApplePayReceiptView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 