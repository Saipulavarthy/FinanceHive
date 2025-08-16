import Foundation

@MainActor
class AssistantStore: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isTyping = false
    private let transactionStore: TransactionStore
    private let stockStore: StockStore
    
    init(transactionStore: TransactionStore, stockStore: StockStore) {
        self.transactionStore = transactionStore
        self.stockStore = stockStore
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        messages.append(.assistant("👋 Hi! I'm FinBot, your AI stock market assistant. Ask me about stock trends, predictions, or market insights!"))
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
        let totalIncome = transactionStore.totalIncome
        let totalExpenses = transactionStore.totalExpenses
        let balance = totalIncome - totalExpenses
        let budgetCount = transactionStore.budgets.count
        let transactionCount = transactionStore.transactions.count
        
        return """
        User's Financial Context:
        - Total Income: $\(String(format: "%.2f", totalIncome))
        - Total Expenses: $\(String(format: "%.2f", totalExpenses))
        - Current Balance: $\(String(format: "%.2f", balance))
        - Active Budgets: \(budgetCount)
        - Total Transactions: \(transactionCount)
        
        User Question: \(query)
        
        Please provide personalized financial advice based on this data.
        """
    }
    
    // MARK: - Canned Response System
    private func getCannedResponse(for message: String) -> String {
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
        let budgetCount = transactionStore.budgets.count
        let totalBudget = transactionStore.budgets.reduce(0) { $0 + $1.amount }
        
        if budgetCount == 0 {
            return "💰 I can help you create your first budget! Start by setting spending limits for categories like groceries, entertainment, and transportation. Would you like to add a budget?"
        } else {
            return "📊 You have \(budgetCount) active budgets totaling $\(String(format: "%.2f", totalBudget)). I can help you analyze your budget performance or create new ones. What would you like to know?"
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