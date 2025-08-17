import Foundation

@MainActor
class AssistantStore: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isTyping = false
    private let transactionStore: TransactionStore
    private let stockStore: StockStore
    private let userStore: UserStore
    
    // AI-powered financial advisors
    @Published var budgetAdjuster: BudgetAdjuster
    @Published var reminderManager: SmartReminderManager
    
    init(transactionStore: TransactionStore, stockStore: StockStore, userStore: UserStore) {
        self.transactionStore = transactionStore
        self.stockStore = stockStore
        self.userStore = userStore
        self.budgetAdjuster = BudgetAdjuster(transactionStore: transactionStore, userStore: userStore)
        self.reminderManager = SmartReminderManager(transactionStore: transactionStore, userStore: userStore)
        addWelcomeMessage()
        startProactiveMessaging()
    }
    
    private func addWelcomeMessage() {
        let finBotSettings = userStore.currentUser?.finBotSettings ?? FinBotSettings.default()
        let welcomeMessage = finBotSettings.getGreeting()
        messages.append(.assistant(welcomeMessage))
    }
    
    func sendMessage(_ content: String) {
        messages.append(.user(content))
        isTyping = true
        Task {
            let response = await fetchAIResponse(for: content)
            messages.append(.assistant(response))
            isTyping = false
        }
    }
    
    // Hybrid approach: Use OpenAI API for complex queries, canned responses for simple ones
    private func fetchAIResponse(for query: String) async -> String {
        // Check if we should use AI or canned response
        if shouldUseAI(for: query) {
            return await getAIResponse(for: query)
        } else {
            // Simulate thinking delay for canned responses
            try? await Task.sleep(nanoseconds: 500_000_000)
            return getCannedResponse(for: query)
        }
    }
    
    private func shouldUseAI(for query: String) -> Bool {
        let lowercased = query.lowercased()
        
        // Use AI for complex questions (contains question words or is long)
        let complexIndicators = ["why", "how", "what if", "explain", "analyze", "compare", "should i", "help me"]
        let hasComplexIndicator = complexIndicators.contains { lowercased.contains($0) }
        let isLongQuery = query.count > 30
        let hasQuestionMark = query.contains("?")
        
        return hasComplexIndicator || isLongQuery || hasQuestionMark
    }
    
    private func getAIResponse(for query: String) async -> String {
        do {
            let contextualPrompt = buildContextualPrompt(for: query)
            let response = try await OpenAIService.shared.generateResponse(for: contextualPrompt)
            return response
        } catch {
            // Fallback to canned response if API fails
            return getCannedResponse(for: query) + "\n\n(Using offline mode)"
        }
    }
    
    private func buildContextualPrompt(for query: String) -> String {
        let finBotSettings = userStore.currentUser?.finBotSettings ?? FinBotSettings.default()
        let totalIncome = transactionStore.totalIncome
        let totalExpenses = transactionStore.totalExpenses
        let balance = totalIncome - totalExpenses
        let budgetCount = transactionStore.budgets.count
        let transactionCount = transactionStore.transactions.count
        
        return """
        \(finBotSettings.personalityPrompt())
        
        User's Financial Context:
        - Total Income: $\(String(format: "%.2f", totalIncome))
        - Total Expenses: $\(String(format: "%.2f", totalExpenses))
        - Current Balance: $\(String(format: "%.2f", balance))
        - Active Budgets: \(budgetCount)
        - Total Transactions: \(transactionCount)
        
        User Question: \(query)
        
        Respond in your assigned personality while providing personalized financial advice based on this data.
        """
    }
    
    // MARK: - Proactive AI Messaging
    
    private func startProactiveMessaging() {
        // Check for proactive messages every 2 hours
        Timer.scheduledTimer(withTimeInterval: 7200, repeats: true) { _ in
            Task { @MainActor in
                await self.checkForProactiveMessages()
            }
        }
        
        // Initial check after 30 seconds
        Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await checkForProactiveMessages()
        }
    }
    
    private func checkForProactiveMessages() async {
        // Check for budget adjustments
        if !budgetAdjuster.pendingAdjustments.isEmpty {
            await sendBudgetAdjustmentMessage()
        }
        
        // Check for due reminders
        let dueReminders = reminderManager.overDueReminders
        if !dueReminders.isEmpty {
            await sendReminderMessage(for: dueReminders)
        }
        
        // Check for upcoming reminders
        let upcomingReminders = reminderManager.upcomingReminders
        if !upcomingReminders.isEmpty && shouldSendUpcomingReminders() {
            await sendUpcomingReminderMessage(for: upcomingReminders)
        }
    }
    
    private func sendBudgetAdjustmentMessage() async {
        let finBotSettings = userStore.currentUser?.finBotSettings ?? FinBotSettings.default()
        let adjustments = budgetAdjuster.pendingAdjustments.prefix(3) // Show top 3
        
        var message = ""
        
        switch finBotSettings.mood {
        case .professional:
            message = "I've analyzed your spending patterns and identified \(adjustments.count) budget optimization opportunities. "
        case .friendly:
            message = finBotSettings.useEmojis ? 
                "Hey! 💡 I noticed some ways we could improve your budget. " :
                "Hey! I noticed some ways we could improve your budget. "
        case .enthusiastic:
            message = finBotSettings.useEmojis ?
                "🎉 Great news! I found some smart budget adjustments that could help you save money! " :
                "Great news! I found some smart budget adjustments that could help you save money! "
        case .supportive:
            message = finBotSettings.useEmojis ?
                "🤗 I'm here to help optimize your budget. I found some gentle adjustments that might work well for you. " :
                "I'm here to help optimize your budget. I found some gentle adjustments that might work well for you. "
        case .witty:
            message = finBotSettings.useEmojis ?
                "🧠 Your budget could use a little AI magic! I've spotted some opportunities to make your money work smarter. " :
                "Your budget could use a little AI magic! I've spotted some opportunities to make your money work smarter. "
        case .motivational:
            message = finBotSettings.useEmojis ?
                "💪 Let's level up your financial game! I found some powerful budget optimizations. " :
                "Let's level up your financial game! I found some powerful budget optimizations. "
        }
        
        for adjustment in adjustments {
            let changeAmount = abs(adjustment.adjustmentAmount)
            let direction = adjustment.isIncrease ? "increase" : "decrease"
            message += "\n\n• \(adjustment.category.rawValue): \(direction) by $\(String(format: "%.0f", changeAmount)) - \(adjustment.reason.rawValue)"
        }
        
        message += "\n\nWould you like me to explain these suggestions in detail?"
        
        messages.append(.assistant(message))
    }
    
    private func sendReminderMessage(for reminders: [SmartReminder]) async {
        let finBotSettings = userStore.currentUser?.finBotSettings ?? FinBotSettings.default()
        let topReminders = reminders.prefix(3)
        
        var message = ""
        
        switch finBotSettings.mood {
        case .professional:
            message = "You have \(topReminders.count) overdue financial obligations requiring attention:"
        case .friendly:
            message = finBotSettings.useEmojis ?
                "Hey! 📅 Just a friendly reminder - you have some items that need attention:" :
                "Hey! Just a friendly reminder - you have some items that need attention:"
        case .enthusiastic:
            message = finBotSettings.useEmojis ?
                "⏰ Time to tackle some financial tasks! You've got this!" :
                "Time to tackle some financial tasks! You've got this!"
        case .supportive:
            message = finBotSettings.useEmojis ?
                "🤗 No worries - I'm here to help you stay on top of these items:" :
                "No worries - I'm here to help you stay on top of these items:"
        case .witty:
            message = finBotSettings.useEmojis ?
                "🎯 Your future self will thank you for handling these now!" :
                "Your future self will thank you for handling these now!"
        case .motivational:
            message = finBotSettings.useEmojis ?
                "💪 Let's crush these financial tasks together!" :
                "Let's crush these financial tasks together!"
        }
        
        for reminder in topReminders {
            let daysPast = abs(reminder.daysUntilDue)
            message += "\n\n• \(reminder.title)"
            if let amount = reminder.amount {
                message += " (\(reminder.formattedAmount))"
            }
            message += " - \(daysPast) days overdue"
        }
        
        message += "\n\nShould I help you create a plan to catch up?"
        
        messages.append(.assistant(message))
    }
    
    private func sendUpcomingReminderMessage(for reminders: [SmartReminder]) async {
        let finBotSettings = userStore.currentUser?.finBotSettings ?? FinBotSettings.default()
        let nextReminder = reminders.first!
        
        var message = ""
        
        switch finBotSettings.mood {
        case .professional:
            message = "Upcoming financial obligation: \(nextReminder.title)"
        case .friendly:
            message = finBotSettings.useEmojis ?
                "📅 Quick heads up! \(nextReminder.title) is coming up in \(nextReminder.daysUntilDue) days." :
                "Quick heads up! \(nextReminder.title) is coming up in \(nextReminder.daysUntilDue) days."
        case .enthusiastic:
            message = finBotSettings.useEmojis ?
                "🗓️ Exciting planning time! \(nextReminder.title) is due in \(nextReminder.daysUntilDue) days!" :
                "Planning time! \(nextReminder.title) is due in \(nextReminder.daysUntilDue) days!"
        case .supportive:
            message = finBotSettings.useEmojis ?
                "🤗 Just a gentle reminder: \(nextReminder.title) is due in \(nextReminder.daysUntilDue) days. You've got this!" :
                "Just a gentle reminder: \(nextReminder.title) is due in \(nextReminder.daysUntilDue) days. You've got this!"
        case .witty:
            message = finBotSettings.useEmojis ?
                "🧠 Time to be proactive! \(nextReminder.title) is sneaking up in \(nextReminder.daysUntilDue) days." :
                "Time to be proactive! \(nextReminder.title) is sneaking up in \(nextReminder.daysUntilDue) days."
        case .motivational:
            message = finBotSettings.useEmojis ?
                "💪 Stay ahead of the game! \(nextReminder.title) is in \(nextReminder.daysUntilDue) days - you're crushing your financial management!" :
                "Stay ahead of the game! \(nextReminder.title) is in \(nextReminder.daysUntilDue) days - you're crushing your financial management!"
        }
        
        if let amount = nextReminder.amount {
            message += " Amount: \(nextReminder.formattedAmount)."
        }
        
        messages.append(.assistant(message))
    }
    
    private func shouldSendUpcomingReminders() -> Bool {
        // Only send upcoming reminder messages once per day
        let lastMessage = messages.last
        guard let lastMessageTime = lastMessage?.timestamp else { return true }
        
        let timeSinceLastMessage = Date().timeIntervalSince(lastMessageTime)
        return timeSinceLastMessage > 86400 // 24 hours
    }
    
    // MARK: - Canned Response System
    private func getCannedResponse(for message: String) -> String {
        let finBotSettings = userStore.currentUser?.finBotSettings ?? FinBotSettings.default()
        let lowercasedMessage = message.lowercased()
        
        // Budget-related keywords
        if containsKeywords(lowercasedMessage, ["budget", "budgeting", "spending limit"]) {
            return generateBudgetResponse()
        }
        
        // Expense-related keywords
        else if containsKeywords(lowercasedMessage, ["expense", "expenses", "spending", "cost"]) {
            return generateExpenseResponse()
        }
        
        // Goal-related keywords
        else if containsKeywords(lowercasedMessage, ["goal", "goals", "target", "save", "saving"]) {
            return generateGoalResponse()
        }
        
        // Income-related keywords
        else if containsKeywords(lowercasedMessage, ["income", "salary", "earnings", "money in"]) {
            return generateIncomeResponse()
        }
        
        // Investment-related keywords
        else if containsKeywords(lowercasedMessage, ["invest", "investment", "stock", "portfolio"]) {
            return generateInvestmentResponse()
        }
        
        // Debt-related keywords
        else if containsKeywords(lowercasedMessage, ["debt", "loan", "credit", "owe"]) {
            return generateDebtResponse()
        }
        
        // Analysis-related keywords
        else if containsKeywords(lowercasedMessage, ["analyze", "analysis", "report", "summary"]) {
            return generateAnalysisResponse()
        }
        
        // Help-related keywords
        else if containsKeywords(lowercasedMessage, ["help", "how", "what", "explain"]) {
            return generateHelpResponse()
        }
        
        // Default response
        else {
            return getDefaultResponse()
        }
    }
    
    private func containsKeywords(_ message: String, _ keywords: [String]) -> Bool {
        return keywords.contains { keyword in
            message.contains(keyword)
        }
    }
    
    // MARK: - Response Generators
    private func generateBudgetResponse() -> String {
        let finBotSettings = userStore.currentUser?.finBotSettings ?? FinBotSettings.default()
        let budgetCount = transactionStore.budgets.count
        let totalBudget = transactionStore.budgets.reduce(0) { $0 + $1.amount }
        let emoji = finBotSettings.useEmojis
        
        if budgetCount == 0 {
            switch finBotSettings.mood {
            case .professional:
                return "I recommend establishing budget allocations for your expense categories. Consider setting limits for essential categories such as groceries, utilities, and discretionary spending."
            case .friendly:
                return emoji ? "Hey! 😊 Let's get you started with budgeting! It's super helpful to set spending limits for things like groceries and entertainment. Want to create your first budget?" : "Hey! Let's get you started with budgeting! It's really helpful to set spending limits. Want to create your first budget?"
            case .enthusiastic:
                return emoji ? "🎉 Budgeting time! This is going to be amazing for your financial journey! Let's set some spending limits and take control of your money! Ready to create your first budget?" : "Budgeting time! This is going to be amazing for your financial journey! Ready to create your first budget?"
            case .supportive:
                return emoji ? "🤗 Don't worry, budgeting can feel overwhelming at first, but I'm here to help! Starting with simple spending limits for categories like groceries is a great first step." : "Don't worry, budgeting can feel overwhelming at first, but I'm here to help! Starting with simple spending limits is a great first step."
            case .witty:
                return emoji ? "💰 Ah, the art of budgeting! It's like being your own financial boss - except you actually have to listen to yourself! Want to set some spending boundaries?" : "Ah, the art of budgeting! It's like being your own financial boss. Want to set some spending boundaries?"
            case .motivational:
                return emoji ? "💪 Every financial champion starts with a budget! This is your foundation for building wealth and achieving your dreams. Let's create that first budget and start winning!" : "Every financial champion starts with a budget! This is your foundation for building wealth. Let's create that first budget!"
            }
        } else {
            let baseInfo = "You have \(budgetCount) active budgets totaling $\(String(format: "%.2f", totalBudget))"
            switch finBotSettings.mood {
            case .professional:
                return "\(emoji ? "📊 " : "")\(baseInfo). I can provide budget performance analysis or assist with creating additional budget categories."
            case .friendly:
                return "\(emoji ? "📊 " : "")\(baseInfo). I can help you see how you're doing or set up new budgets. What sounds good?"
            case .enthusiastic:
                return "\(emoji ? "🎉 " : "")\(baseInfo)! You're crushing it with your budget game! Want to dive deeper into your progress?"
            case .supportive:
                return "\(emoji ? "🤗 " : "")\(baseInfo). You're doing great with budgeting! I'm here to help you analyze your progress or expand your budgets."
            case .witty:
                return "\(emoji ? "📊 " : "")\(baseInfo). Look at you being all financially responsible! Want to see how well you're sticking to these budgets?"
            case .motivational:
                return "\(emoji ? "💪 " : "")\(baseInfo). You're building financial discipline! Let's analyze your progress and keep pushing toward your goals!"
            }
        }
    }
    
    private func generateExpenseResponse() -> String {
        let totalExpenses = transactionStore.totalExpenses
        let transactionCount = transactionStore.transactions.filter { $0.type == .expense }.count
        
        return "💸 You've recorded \(transactionCount) expenses totaling $\(String(format: "%.2f", totalExpenses)). I can help you categorize expenses, find spending patterns, or scan receipts. What would you like to do?"
    }
    
    private func generateGoalResponse() -> String {
        let balance = transactionStore.totalIncome - transactionStore.totalExpenses
        
        return "🎯 Setting financial goals is smart! Based on your current balance of $\(String(format: "%.2f", balance)), I can help you create savings goals or track progress. What goal would you like to work on?"
    }
    
    private func generateIncomeResponse() -> String {
        let totalIncome = transactionStore.totalIncome
        
        return "💰 Your total recorded income is $\(String(format: "%.2f", totalIncome)). I can help you track income sources, analyze trends, or plan for income growth. What would you like to explore?"
    }
    
    private func generateInvestmentResponse() -> String {
        return "📈 I can help you understand investment basics, analyze your portfolio, or discuss investment strategies. Remember, all investments carry risk. What aspect of investing interests you?"
    }
    
    private func generateDebtResponse() -> String {
        return "💳 Managing debt is crucial for financial health. I can help you create a debt payoff plan, understand interest rates, or prioritize payments. What debt concerns do you have?"
    }
    
    private func generateAnalysisResponse() -> String {
        let expenseCategories = Set(transactionStore.transactions.filter { $0.type == .expense }.map { $0.category })
        
        return "📊 I can analyze your spending patterns across \(expenseCategories.count) categories, show trends over time, and identify areas for improvement. What analysis would you like to see?"
    }
    
    private func generateHelpResponse() -> String {
        return "🤔 I'm here to help with your finances! I can:\n\n• Analyze your spending patterns\n• Help create and track budgets\n• Scan receipts for expenses\n• Provide financial insights\n• Answer money questions\n\nWhat specific help do you need?"
    }
    
    private func getDefaultResponse() -> String {
        let responses = [
            "🤖 I'm FinBot, your personal finance assistant! Ask me about budgets, expenses, goals, or any financial topic.",
            "💡 I can help you understand your spending, create budgets, or analyze financial trends. What would you like to know?",
            "📱 Try asking about your expenses, setting up a budget, or scanning a receipt. I'm here to help!",
            "💬 I'm not sure I understand. Could you ask about budgets, expenses, savings goals, or another financial topic?"
        ]
        
        return responses.randomElement() ?? responses[0]
    }
} 