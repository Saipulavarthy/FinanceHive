import Foundation
import SwiftUI
import UserNotifications

// MARK: - Smart Reminder Models

enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case bill = "Bill Payment"
    case subscription = "Subscription"
    case savingsGoal = "Savings Goal"
    case budgetCheck = "Budget Review"
    case expenseEntry = "Expense Entry"
    case incomeTracking = "Income Tracking"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .bill: return "doc.text.fill"
        case .subscription: return "arrow.clockwise.circle.fill"
        case .savingsGoal: return "target"
        case .budgetCheck: return "chart.pie.fill"
        case .expenseEntry: return "plus.circle.fill"
        case .incomeTracking: return "dollarsign.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bill: return .red
        case .subscription: return .orange
        case .savingsGoal: return .green
        case .budgetCheck: return .blue
        case .expenseEntry: return .purple
        case .incomeTracking: return .teal
        }
    }
    
    var defaultMessage: String {
        switch self {
        case .bill: return "Don't forget to pay your bill!"
        case .subscription: return "Subscription payment is due soon"
        case .savingsGoal: return "Time to contribute to your savings goal"
        case .budgetCheck: return "Review your monthly budget progress"
        case .expenseEntry: return "Don't forget to log today's expenses"
        case .incomeTracking: return "Record your income for this period"
        }
    }
}

enum ReminderFrequency: String, Codable, CaseIterable, Identifiable {
    case once = "Once"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    case custom = "Custom"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .once: return "One-time reminder"
        case .daily: return "Every day"
        case .weekly: return "Every week"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Every month"
        case .quarterly: return "Every 3 months"
        case .yearly: return "Every year"
        case .custom: return "Custom schedule"
        }
    }
    
    func nextDate(from date: Date) -> Date? {
        let calendar = Calendar.current
        
        switch self {
        case .once:
            return nil // No repeat
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        case .custom:
            return nil // Handled separately
        }
    }
}

enum ReminderPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

struct SmartReminder: Identifiable, Codable {
    let id: String
    var title: String
    var message: String
    var type: ReminderType
    var amount: Double? // For bills, subscriptions, savings goals
    var dueDate: Date
    var frequency: ReminderFrequency
    var priority: ReminderPriority
    var isActive: Bool
    var isCompleted: Bool
    var completedDate: Date?
    var nextReminderDate: Date?
    var advanceNotice: TimeInterval // How many seconds before due date to remind
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var category: Transaction.Category?
    
    // Auto-generated suggestions
    var suggestedByAI: Bool
    var aiConfidence: Double?
    
    init(
        title: String,
        message: String = "",
        type: ReminderType,
        amount: Double? = nil,
        dueDate: Date,
        frequency: ReminderFrequency = .once,
        priority: ReminderPriority = .medium,
        advanceNotice: TimeInterval = 86400, // 24 hours default
        category: Transaction.Category? = nil,
        tags: [String] = [],
        suggestedByAI: Bool = false,
        aiConfidence: Double? = nil
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.message = message.isEmpty ? type.defaultMessage : message
        self.type = type
        self.amount = amount
        self.dueDate = dueDate
        self.frequency = frequency
        self.priority = priority
        self.advanceNotice = advanceNotice
        self.category = category
        self.tags = tags
        self.suggestedByAI = suggestedByAI
        self.aiConfidence = aiConfidence
        
        self.isActive = true
        self.isCompleted = false
        self.completedDate = nil
        self.nextReminderDate = Date(timeInterval: -advanceNotice, since: dueDate)
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var isDue: Bool {
        return Date() >= dueDate && !isCompleted
    }
    
    var isOverdue: Bool {
        return Date() > dueDate && !isCompleted
    }
    
    var shouldRemind: Bool {
        guard isActive && !isCompleted else { return false }
        guard let reminderDate = nextReminderDate else { return false }
        return Date() >= reminderDate
    }
    
    var daysUntilDue: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        return max(0, days)
    }
    
    var formattedAmount: String {
        guard let amount = amount else { return "" }
        return "$\(String(format: "%.2f", amount))"
    }
    
    var urgencyLevel: UrgencyLevel {
        if isOverdue { return .overdue }
        
        let hoursUntilDue = dueDate.timeIntervalSinceNow / 3600
        
        switch priority {
        case .critical:
            if hoursUntilDue <= 24 { return .urgent }
            if hoursUntilDue <= 72 { return .soon }
            return .upcoming
        case .high:
            if hoursUntilDue <= 12 { return .urgent }
            if hoursUntilDue <= 48 { return .soon }
            return .upcoming
        case .medium:
            if hoursUntilDue <= 6 { return .urgent }
            if hoursUntilDue <= 24 { return .soon }
            return .upcoming
        case .low:
            if hoursUntilDue <= 2 { return .urgent }
            if hoursUntilDue <= 12 { return .soon }
            return .upcoming
        }
    }
    
    enum UrgencyLevel: String, CaseIterable {
        case overdue = "Overdue"
        case urgent = "Urgent"
        case soon = "Due Soon"
        case upcoming = "Upcoming"
        
        var color: Color {
            switch self {
            case .overdue: return .red
            case .urgent: return .orange
            case .soon: return .yellow
            case .upcoming: return .green
            }
        }
    }
    
    mutating func markCompleted() {
        isCompleted = true
        completedDate = Date()
        updatedAt = Date()
        
        // Schedule next reminder if recurring
        if frequency != .once, let nextDate = frequency.nextDate(from: dueDate) {
            dueDate = nextDate
            nextReminderDate = Date(timeInterval: -advanceNotice, since: nextDate)
            isCompleted = false
            completedDate = nil
        }
    }
    
    mutating func snooze(for interval: TimeInterval) {
        if let reminderDate = nextReminderDate {
            nextReminderDate = reminderDate.addingTimeInterval(interval)
        }
        updatedAt = Date()
    }
    
    mutating func updateNextReminderDate() {
        nextReminderDate = Date(timeInterval: -advanceNotice, since: dueDate)
        updatedAt = Date()
    }
}

// MARK: - Smart Reminder Manager

@MainActor
class SmartReminderManager: ObservableObject {
    @Published var reminders: [SmartReminder] = []
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    
    private let transactionStore: TransactionStore
    private let userStore: UserStore
    private var reminderTimer: Timer?
    
    init(transactionStore: TransactionStore, userStore: UserStore) {
        self.transactionStore = transactionStore
        self.userStore = userStore
        loadReminders()
        startReminderEngine()
        requestNotificationPermissions()
    }
    
    // MARK: - AI-Powered Reminder Generation
    
    func generateSmartReminders() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        var aiGeneratedReminders: [SmartReminder] = []
        
        // 1. Analyze transaction patterns for bill reminders
        aiGeneratedReminders.append(contentsOf: await generateBillReminders())
        
        // 2. Detect subscription patterns
        aiGeneratedReminders.append(contentsOf: await generateSubscriptionReminders())
        
        // 3. Suggest savings goal reminders
        aiGeneratedReminders.append(contentsOf: await generateSavingsReminders())
        
        // 4. Budget review reminders
        aiGeneratedReminders.append(contentsOf: await generateBudgetReminders())
        
        // 5. Expense tracking reminders
        aiGeneratedReminders.append(contentsOf: await generateExpenseTrackingReminders())
        
        // Filter out duplicates and low-confidence suggestions
        let filteredReminders = aiGeneratedReminders
            .filter { reminder in
                guard let confidence = reminder.aiConfidence else { return true }
                return confidence > 0.6
            }
            .filter { newReminder in
                !reminders.contains { existingReminder in
                    existingReminder.title.lowercased() == newReminder.title.lowercased() &&
                    existingReminder.type == newReminder.type
                }
            }
        
        reminders.append(contentsOf: filteredReminders)
        saveReminders()
        lastAnalysisDate = Date()
    }
    
    private func generateBillReminders() async -> [SmartReminder] {
        var suggestions: [SmartReminder] = []
        
        // Analyze recurring expense patterns
        let expenses = transactionStore.transactions.filter { $0.type == .expense }
        let recurringExpenses = findRecurringExpenses(in: expenses)
        
        for recurring in recurringExpenses {
            // Skip if we already have a reminder for this
            let existingReminder = reminders.first { reminder in
                reminder.title.lowercased().contains(recurring.description.lowercased()) ||
                reminder.amount == recurring.amount
            }
            
            if existingReminder == nil {
                let nextDueDate = predictNextDueDate(for: recurring)
                
                let reminder = SmartReminder(
                    title: recurring.description,
                    message: "Your \(recurring.description) payment of \(String(format: "$%.2f", recurring.amount)) is due soon",
                    type: .bill,
                    amount: recurring.amount,
                    dueDate: nextDueDate,
                    frequency: recurring.frequency,
                    priority: recurring.amount > 100 ? .high : .medium,
                    advanceNotice: 86400 * 3, // 3 days advance notice
                    category: recurring.category,
                    suggestedByAI: true,
                    aiConfidence: recurring.confidence
                )
                
                suggestions.append(reminder)
            }
        }
        
        return suggestions
    }
    
    private func generateSubscriptionReminders() async -> [SmartReminder] {
        var suggestions: [SmartReminder] = []
        
        // Common subscription patterns
        let subscriptionKeywords = ["netflix", "spotify", "apple", "amazon", "subscription", "monthly", "premium"]
        
        let subscriptionExpenses = transactionStore.transactions.filter { transaction in
            subscriptionKeywords.contains { keyword in
                transaction.description?.lowercased().contains(keyword) ?? false
            }
        }
        
        let groupedSubscriptions = Dictionary(grouping: subscriptionExpenses) { transaction in
            transaction.description?.lowercased() ?? "unknown"
        }
        
        for (serviceName, transactions) in groupedSubscriptions {
            let sortedTransactions = transactions.sorted { $0.date > $1.date }
            guard let lastTransaction = sortedTransactions.first,
                  transactions.count >= 2 else { continue }
            
            // Calculate average interval between payments
            let intervals = zip(sortedTransactions, sortedTransactions.dropFirst()).map { recent, previous in
                recent.date.timeIntervalSince(previous.date)
            }
            
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            let nextDueDate = lastTransaction.date.addingTimeInterval(averageInterval)
            
            // Only suggest if next payment is in the future
            if nextDueDate > Date() {
                let frequency: ReminderFrequency
                if averageInterval < 86400 * 10 { // Less than 10 days
                    frequency = .weekly
                } else if averageInterval < 86400 * 40 { // Less than 40 days
                    frequency = .monthly
                } else {
                    frequency = .quarterly
                }
                
                let reminder = SmartReminder(
                    title: serviceName.capitalized,
                    message: "Your \(serviceName.capitalized) subscription renewal is due",
                    type: .subscription,
                    amount: lastTransaction.amount,
                    dueDate: nextDueDate,
                    frequency: frequency,
                    priority: .medium,
                    advanceNotice: 86400 * 2, // 2 days advance notice
                    category: lastTransaction.category,
                    suggestedByAI: true,
                    aiConfidence: 0.8
                )
                
                suggestions.append(reminder)
            }
        }
        
        return suggestions
    }
    
    private func generateSavingsReminders() async -> [SmartReminder] {
        var suggestions: [SmartReminder] = []
        
        let totalIncome = transactionStore.totalIncome
        let totalExpenses = transactionStore.totalExpenses
        let availableForSavings = totalIncome - totalExpenses
        
        if availableForSavings > 100 { // Only suggest if there's money available
            // Emergency fund reminder
            let emergencyGoal = totalExpenses * 0.25 // 3 months of expenses (quarterly check)
            if availableForSavings < emergencyGoal {
                let monthlySavingsTarget = min(availableForSavings * 0.2, 500) // 20% of available or $500 max
                
                let reminder = SmartReminder(
                    title: "Emergency Fund Contribution",
                    message: "Add $\(String(format: "%.0f", monthlySavingsTarget)) to your emergency fund this month",
                    type: .savingsGoal,
                    amount: monthlySavingsTarget,
                    dueDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date(),
                    frequency: .weekly,
                    priority: .high,
                    advanceNotice: 0, // Immediate reminder
                    suggestedByAI: true,
                    aiConfidence: 0.9
                )
                
                suggestions.append(reminder)
            }
        }
        
        return suggestions
    }
    
    private func generateBudgetReminders() async -> [SmartReminder] {
        var suggestions: [SmartReminder] = []
        
        // Monthly budget review reminder
        let nextMonthStart = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        
        let reminder = SmartReminder(
            title: "Monthly Budget Review",
            message: "Review your budget performance and adjust for next month",
            type: .budgetCheck,
            dueDate: nextMonthStart,
            frequency: .monthly,
            priority: .medium,
            advanceNotice: 86400 * 3, // 3 days before month end
            suggestedByAI: true,
            aiConfidence: 0.9
        )
        
        suggestions.append(reminder)
        
        return suggestions
    }
    
    private func generateExpenseTrackingReminders() async -> [SmartReminder] {
        var suggestions: [SmartReminder] = []
        
        // Check if user has been consistently logging expenses
        let lastWeekTransactions = transactionStore.transactions.filter { transaction in
            transaction.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }
        
        if lastWeekTransactions.count < 3 { // If less than 3 transactions in last week
            let reminder = SmartReminder(
                title: "Daily Expense Check-in",
                message: "Don't forget to log your expenses for today to stay on track",
                type: .expenseEntry,
                dueDate: Calendar.current.date(byAdding: .hour, value: 20, to: Date()) ?? Date(), // 8 PM today
                frequency: .daily,
                priority: .low,
                advanceNotice: 0,
                suggestedByAI: true,
                aiConfidence: 0.7
            )
            
            suggestions.append(reminder)
        }
        
        return suggestions
    }
    
    // MARK: - Reminder Management
    
    func addReminder(_ reminder: SmartReminder) {
        reminders.append(reminder)
        scheduleLocalNotification(for: reminder)
        saveReminders()
    }
    
    func updateReminder(_ reminder: SmartReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            scheduleLocalNotification(for: reminder)
            saveReminders()
        }
    }
    
    func deleteReminder(_ reminder: SmartReminder) {
        reminders.removeAll { $0.id == reminder.id }
        cancelLocalNotification(for: reminder)
        saveReminders()
    }
    
    func markReminderCompleted(_ reminder: SmartReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].markCompleted()
            
            // If it's a recurring reminder, schedule the next notification
            if reminders[index].frequency != .once {
                scheduleLocalNotification(for: reminders[index])
            }
            
            saveReminders()
        }
    }
    
    func snoozeReminder(_ reminder: SmartReminder, for interval: TimeInterval) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].snooze(for: interval)
            scheduleLocalNotification(for: reminders[index])
            saveReminders()
        }
    }
    
    // MARK: - Filtering and Sorting
    
    var activeReminders: [SmartReminder] {
        return reminders.filter { $0.isActive && !$0.isCompleted }
            .sorted { first, second in
                if first.urgencyLevel != second.urgencyLevel {
                    return first.urgencyLevel.rawValue < second.urgencyLevel.rawValue
                }
                return first.dueDate < second.dueDate
            }
    }
    
    var overDueReminders: [SmartReminder] {
        return reminders.filter { $0.isOverdue }
    }
    
    var upcomingReminders: [SmartReminder] {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return reminders.filter { $0.dueDate <= nextWeek && !$0.isCompleted }
    }
    
    func reminders(for type: ReminderType) -> [SmartReminder] {
        return reminders.filter { $0.type == type }
    }
    
    // MARK: - Notification Management
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleLocalNotification(for reminder: SmartReminder) {
        guard reminder.isActive && !reminder.isCompleted,
              let reminderDate = reminder.nextReminderDate,
              reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message
        content.sound = .default
        content.categoryIdentifier = "REMINDER_CATEGORY"
        
        // Add action buttons
        let completeAction = UNNotificationAction(identifier: "COMPLETE", title: "Mark Complete", options: [])
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Snooze 1 Hour", options: [])
        let category = UNNotificationCategory(identifier: "REMINDER_CATEGORY", actions: [completeAction, snoozeAction], intentIdentifiers: [], options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func cancelLocalNotification(for reminder: SmartReminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id])
    }
    
    // MARK: - Persistence
    
    private func saveReminders() {
        do {
            let data = try JSONEncoder().encode(reminders)
            UserDefaults.standard.set(data, forKey: "smartReminders")
        } catch {
            print("Failed to save reminders: \(error)")
        }
    }
    
    private func loadReminders() {
        guard let data = UserDefaults.standard.data(forKey: "smartReminders") else {
            createSampleReminders()
            return
        }
        
        do {
            reminders = try JSONDecoder().decode([SmartReminder].self, from: data)
        } catch {
            print("Failed to load reminders: \(error)")
            createSampleReminders()
        }
    }
    
    private func createSampleReminders() {
        let sampleReminders = [
            SmartReminder(
                title: "Rent Payment",
                message: "Monthly rent payment is due",
                type: .bill,
                amount: 1200,
                dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                frequency: .monthly,
                priority: .high,
                category: .rent
            ),
            SmartReminder(
                title: "Emergency Fund Goal",
                message: "Add $200 to your emergency savings",
                type: .savingsGoal,
                amount: 200,
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                frequency: .weekly,
                priority: .medium
            )
        ]
        
        reminders = sampleReminders
        saveReminders()
    }
    
    private func startReminderEngine() {
        // Check for due reminders every hour
        reminderTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in
                await self.generateSmartReminders()
            }
        }
        
        // Initial analysis
        Task {
            await generateSmartReminders()
        }
    }
    
    deinit {
        reminderTimer?.invalidate()
    }
}

// MARK: - Helper Types for Pattern Recognition

struct RecurringExpensePattern {
    let description: String
    let amount: Double
    let category: Transaction.Category
    let frequency: ReminderFrequency
    let confidence: Double
}

extension SmartReminderManager {
    private func findRecurringExpenses(in transactions: [Transaction]) -> [RecurringExpensePattern] {
        // Group transactions by similar amounts and descriptions
        let grouped = Dictionary(grouping: transactions) { transaction in
            "\(transaction.description ?? "unknown")_\(Int(transaction.amount))"
        }
        
        var recurringExpenses: [RecurringExpensePattern] = []
        
        for (_, transactionGroup) in grouped {
            guard transactionGroup.count >= 3 else { continue } // Need at least 3 occurrences
            
            let sortedTransactions = transactionGroup.sorted { $0.date > $1.date }
            let intervals = zip(sortedTransactions, sortedTransactions.dropFirst()).map { recent, previous in
                recent.date.timeIntervalSince(previous.date)
            }
            
            let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
            let standardDeviation = sqrt(intervals.map { pow($0 - averageInterval, 2) }.reduce(0, +) / Double(intervals.count))
            
            // High confidence if intervals are consistent (low standard deviation)
            let confidence = max(0.0, 1.0 - (standardDeviation / averageInterval))
            
            if confidence > 0.6 { // Only consider if reasonably consistent
                let frequency: ReminderFrequency
                if averageInterval < 86400 * 10 { // Less than 10 days
                    frequency = .weekly
                } else if averageInterval < 86400 * 40 { // Less than 40 days
                    frequency = .monthly
                } else if averageInterval < 86400 * 100 { // Less than 100 days
                    frequency = .quarterly
                } else {
                    frequency = .yearly
                }
                
                let recurringExpense = RecurringExpensePattern(
                    description: sortedTransactions.first?.description ?? "Unknown",
                    amount: sortedTransactions.first?.amount ?? 0,
                    category: sortedTransactions.first?.category ?? .other,
                    frequency: frequency,
                    confidence: confidence
                )
                
                recurringExpenses.append(recurringExpense)
            }
        }
        
        return recurringExpenses
    }
    
    private func predictNextDueDate(for recurring: RecurringExpensePattern) -> Date {
        let baseDate = Date()
        
        switch recurring.frequency {
        case .weekly:
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: baseDate) ?? baseDate
        case .quarterly:
            return Calendar.current.date(byAdding: .month, value: 3, to: baseDate) ?? baseDate
        case .yearly:
            return Calendar.current.date(byAdding: .year, value: 1, to: baseDate) ?? baseDate
        default:
            return Calendar.current.date(byAdding: .day, value: 30, to: baseDate) ?? baseDate
        }
    }
}
