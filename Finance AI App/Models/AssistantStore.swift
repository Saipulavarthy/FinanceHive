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
    
    // This function would call the OpenAI API in production. Here, we mock it for now.
    private func fetchAIResponse(for query: String) async -> String {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // Mocked finance-focused response
        if query.lowercased().contains("apple") || query.lowercased().contains("aapl") {
            return "Apple (AAPL) is a leading tech stock. Recent trends show moderate volatility. Would you like a price prediction or sentiment analysis?"
        } else if query.lowercased().contains("predict") || query.lowercased().contains("forecast") {
            return "Stock price predictions are based on historical data and market sentiment. Please specify a stock symbol for a forecast."
        } else if query.lowercased().contains("risk") {
            return "All investments carry risk. Predictions are not guarantees. Diversification and research are key to managing risk."
        } else if query.lowercased().contains("sentiment") {
            return "Market sentiment combines news and social media analysis. Positive sentiment can indicate bullish trends, while negative sentiment may signal caution."
        } else {
            return "I'm here to help with stock trends, predictions, and market insights. Please ask about a specific stock or market topic!"
        }
    }
} 