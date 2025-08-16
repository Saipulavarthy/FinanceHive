import SwiftUI

struct VoiceExpenseView: View {
    @StateObject private var voiceService = VoiceExpenseService()
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    @State private var showingConfirmation = false
    @State private var editableAmount = ""
    @State private var editableMerchant = ""
    @State private var editableDescription = ""
    @State private var editableCategory: Transaction.Category = .other
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Voice Recording Section
                VStack(spacing: 16) {
                    // Microphone Button
                    Button(action: toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(voiceService.isRecording ? 
                                      LinearGradient(gradient: Gradient(colors: [Color.red, Color.pink]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                                      LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 120, height: 120)
                                .scaleEffect(voiceService.isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: voiceService.isRecording)
                            
                            Image(systemName: voiceService.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(voiceService.permissionStatus != .authorized)
                    
                    // Status Text
                    Text(statusText)
                        .font(.headline)
                        .foregroundColor(voiceService.isRecording ? .red : .primary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                // Transcription Display
                if !voiceService.transcribedText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("You said:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(voiceService.transcribedText)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Parsed Expense Preview
                if let expense = voiceService.parsedExpense {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Parsed Expense:")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        ExpensePreviewCard(expense: expense)
                        
                        Button(action: { showEditView(expense) }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Confirm & Save")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Error Message
                if let error = voiceService.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Permission Status
                if voiceService.permissionStatus != .authorized {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                        
                        Text(permissionMessage)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        if voiceService.permissionStatus == .notDetermined {
                            Button("Grant Permission") {
                                voiceService.requestPermissions()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Voice Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Clear") { clearAll() }
            )
        }
        .sheet(isPresented: $showingConfirmation) {
            ExpenseConfirmationView(
                amount: $editableAmount,
                merchant: $editableMerchant,
                description: $editableDescription,
                category: $editableCategory,
                onSave: saveExpense,
                onCancel: { showingConfirmation = false }
            )
        }
        .onDisappear {
            if voiceService.isRecording {
                voiceService.stopRecording()
            }
        }
    }
    
    private var statusText: String {
        if voiceService.permissionStatus != .authorized {
            return "Speech recognition permission required"
        } else if voiceService.isRecording {
            return "Listening... Tap to stop"
        } else {
            return "Tap to record your expense"
        }
    }
    
    private var permissionMessage: String {
        switch voiceService.permissionStatus {
        case .notDetermined:
            return "Voice expense logging requires speech recognition permission. Tap below to grant access."
        case .denied:
            return "Speech recognition access was denied. Please enable it in Settings > Privacy & Security > Speech Recognition."
        case .restricted:
            return "Speech recognition is restricted on this device."
        case .authorized:
            return ""
        }
    }
    
    private func toggleRecording() {
        if voiceService.isRecording {
            voiceService.stopRecording()
        } else {
            voiceService.startRecording()
        }
    }
    
    private func clearAll() {
        voiceService.transcribedText = ""
        voiceService.parsedExpense = nil
        voiceService.errorMessage = nil
    }
    
    private func showEditView(_ expense: ParsedExpense) {
        editableAmount = String(format: "%.2f", expense.amount)
        editableMerchant = expense.merchant
        editableDescription = expense.description
        editableCategory = expense.category
        showingConfirmation = true
    }
    
    private func saveExpense() {
        guard let amount = Double(editableAmount), amount > 0 else { return }
        
        let expense = RecurringExpense(context: viewContext)
        expense.setValue(amount, forKey: "amount")
        expense.setValue(editableCategory.rawValue, forKey: "category")
        expense.setValue(editableDescription, forKey: "note")
        expense.setValue(Date(), forKey: "date")
        expense.setValue(false, forKey: "isRecurring")
        expense.setValue(nil as String?, forKey: "repeatInterval")
        
        do {
            try viewContext.save()
            isPresented = false
        } catch {
            voiceService.errorMessage = "Failed to save expense: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views

struct ExpensePreviewCard: View {
    let expense: ParsedExpense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Amount:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(String(format: "%.2f", expense.amount))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("Merchant:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(expense.merchant)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Category:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(expense.category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            if !expense.description.isEmpty {
                HStack(alignment: .top) {
                    Text("Note:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(expense.description)
                        .font(.subheadline)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ExpenseConfirmationView: View {
    @Binding var amount: String
    @Binding var merchant: String
    @Binding var description: String
    @Binding var category: Transaction.Category
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Amount")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Merchant")) {
                    TextField("Merchant", text: $merchant)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(Transaction.Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Note")) {
                    TextField("Description", text: $description)
                }
                
                Section {
                    Button("Save Expense") {
                        onSave()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Confirm Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel", action: onCancel)
            )
        }
    }
}

#Preview {
    VoiceExpenseView(isPresented: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
