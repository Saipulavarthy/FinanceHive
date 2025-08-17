import SwiftUI

struct ReminderDetailView: View {
    let reminder: SmartReminder
    @ObservedObject var reminderManager: SmartReminderManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSnoozeOptions = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    reminderHeader
                    
                    // Details Section
                    detailsSection
                    
                    // AI Insights (if AI-generated)
                    if reminder.suggestedByAI {
                        aiInsightsSection
                    }
                    
                    // Actions Section
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") { dismiss() },
                trailing: Button("Edit") {
                    // Edit functionality
                }
            )
            .actionSheet(isPresented: $showingSnoozeOptions) {
                ActionSheet(
                    title: Text("Snooze Reminder"),
                    buttons: [
                        .default(Text("1 Hour")) { snooze(for: 3600) },
                        .default(Text("4 Hours")) { snooze(for: 14400) },
                        .default(Text("Tomorrow")) { snooze(for: 86400) },
                        .default(Text("1 Week")) { snooze(for: 604800) },
                        .cancel()
                    ]
                )
            }
            .alert("Delete Reminder", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    reminderManager.deleteReminder(reminder)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this reminder? This action cannot be undone.")
            }
        }
    }
    
    private var reminderHeader: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(reminder.type.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: reminder.type.icon)
                        .font(.system(size: 30))
                        .foregroundColor(reminder.type.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(reminder.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let amount = reminder.amount {
                        Text(reminder.formattedAmount)
                            .font(.headline)
                            .foregroundColor(reminder.type.color)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
            }
            
            // Status Banner
            HStack {
                Circle()
                    .fill(reminder.urgencyLevel.color)
                    .frame(width: 12, height: 12)
                
                Text(reminder.urgencyLevel.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if reminder.isOverdue {
                    Text("\(abs(reminder.daysUntilDue)) days overdue")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                } else {
                    Text("Due in \(reminder.daysUntilDue) days")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(reminder.urgencyLevel.color.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                DetailRow(title: "Message", value: reminder.message)
                DetailRow(title: "Due Date", value: formatDate(reminder.dueDate))
                DetailRow(title: "Frequency", value: reminder.frequency.rawValue)
                DetailRow(title: "Priority", value: reminder.priority.rawValue)
                
                if let category = reminder.category {
                    DetailRow(title: "Category", value: category.rawValue)
                }
                
                if !reminder.tags.isEmpty {
                    HStack {
                        Text("Tags")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack {
                            ForEach(reminder.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.purple)
                Text("AI Insights")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("This reminder was automatically created by your AI assistant based on your spending patterns.")
                    .font(.body)
                    .foregroundColor(.primary)
                
                if let confidence = reminder.aiConfidence {
                    HStack {
                        Text("AI Confidence:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(confidence * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(confidenceColor(confidence))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                if reminder.type == .bill {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Pattern Recognition", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Your AI assistant detected this as a recurring payment based on transaction history and amount consistency.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if reminder.type == .subscription {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Subscription Detection", systemImage: "arrow.clockwise.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("This appears to be a subscription service based on regular payment intervals and merchant patterns.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Text("Actions")
                .font(.headline)
            
            VStack(spacing: 12) {
                if !reminder.isCompleted {
                    Button(action: markCompleted) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Completed")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { showingSnoozeOptions = true }) {
                        HStack {
                            Image(systemName: "clock.fill")
                            Text("Snooze")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                }
                
                Button(action: { showingDeleteConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Reminder")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func markCompleted() {
        reminderManager.markReminderCompleted(reminder)
        dismiss()
    }
    
    private func snooze(for interval: TimeInterval) {
        reminderManager.snoozeReminder(reminder, for: interval)
        dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence > 0.8 { return .green }
        if confidence > 0.6 { return .orange }
        return .red
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Reminder View

struct CreateReminderView: View {
    @ObservedObject var reminderManager: SmartReminderManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var message = ""
    @State private var selectedType: ReminderType = .bill
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var frequency: ReminderFrequency = .once
    @State private var priority: ReminderPriority = .medium
    @State private var category: Transaction.Category = .other
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Message (Optional)", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(ReminderType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section(header: Text("Details")) {
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(ReminderFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(ReminderPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(Transaction.Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("Tags")) {
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .textInputAutocapitalization(.never)
                        
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        FlowLayout(tags: tags) { tag in
                            TagView(tag: tag) {
                                removeTag(tag)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: createReminder) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Reminder")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Reminder")
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
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func createReminder() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            alertMessage = "Please enter a title for the reminder."
            showingAlert = true
            return
        }
        
        let amountValue = Double(amount.isEmpty ? "0" : amount)
        
        let reminder = SmartReminder(
            title: trimmedTitle,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            type: selectedType,
            amount: amountValue == 0 ? nil : amountValue,
            dueDate: dueDate,
            frequency: frequency,
            priority: priority,
            category: category,
            tags: tags
        )
        
        reminderManager.addReminder(reminder)
        dismiss()
    }
}

struct FlowLayout: View {
    let tags: [String]
    let onDelete: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagView(tag: tag, onDelete: { onDelete(tag) })
            }
        }
    }
}

struct TagView: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(8)
    }
}

struct ReminderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderDetailView(
            reminder: SmartReminder(
                title: "Rent Payment",
                message: "Monthly rent payment is due",
                type: .bill,
                amount: 1200,
                dueDate: Date(),
                frequency: .monthly,
                priority: .high,
                category: .rent,
                suggestedByAI: true,
                aiConfidence: 0.9
            ),
            reminderManager: SmartReminderManager(transactionStore: TransactionStore(), userStore: UserStore())
        )
    }
}
