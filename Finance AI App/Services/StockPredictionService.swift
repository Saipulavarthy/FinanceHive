import Foundation

struct StockPrediction: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let predictedPrices: [PredictedPrice]
    let generatedAt: Date
}

struct PredictedPrice: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let price: Double
    let confidence: Double // 0-1
    let explanation: String
}

struct SentimentScore: Codable {
    let symbol: String
    let score: Double // -1 (very negative) to 1 (very positive)
    let summary: String
    let sources: [String]
}

class StockPredictionService {
    // Fetch real-time price from Yahoo Finance
    static func fetchYahooRealTimePrice(for symbol: String, completion: @escaping (Double?) -> Void) {
        let url = URL(string: "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(symbol)")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(YahooQuoteResponse.self, from: data),
                  let price = decoded.quoteResponse.result.first?.regularMarketPrice else {
                completion(nil)
                return
            }
            completion(price)
        }.resume()
    }

    // Simulate fetching predictions from an API, now using user profile and Yahoo price
    static func fetchPrediction(for symbol: String, userProfile: UserProfile?, completion: @escaping (StockPrediction) -> Void) {
        fetchYahooRealTimePrice(for: symbol) { realTimePrice in
            let today = Date()
            let risk = userProfile?.riskLevel ?? .medium
            let goal = userProfile?.investmentGoal ?? .growth
            let sectors = userProfile?.preferredSectors ?? []
            let explanationBase = "Prediction based on Yahoo real-time price ($\(String(format: "%.2f", realTimePrice ?? 0))). Risk=\(risk.rawValue.capitalized), Goal=\(goal.rawValue.capitalized)\(sectors.isEmpty ? "" : ", Sectors=\(sectors.joined(separator: ", "))")"
            let basePrice = realTimePrice ?? Double.random(in: 100...500)
            let predictedPrices = (1...7).map { i in
                PredictedPrice(
                    date: Calendar.current.date(byAdding: .day, value: i, to: today)!,
                    price: basePrice * Double.random(in: 0.97...1.05),
                    confidence: Double.random(in: 0.6...0.95),
                    explanation: explanationBase + ". Confidence is based on recent volatility and sentiment."
                )
            }
            let prediction = StockPrediction(symbol: symbol, predictedPrices: predictedPrices, generatedAt: today)
            DispatchQueue.main.async {
                completion(prediction)
            }
        }
    }
    
    // Simulate fetching sentiment analysis from an API
    static func fetchSentiment(for symbol: String, completion: @escaping (SentimentScore) -> Void) {
        let sentiments = [
            (0.7, "Positive outlook based on recent news."),
            (0.1, "Neutral sentiment in the market."),
            (-0.5, "Negative sentiment due to recent events.")
        ]
        let pick = sentiments.randomElement()!
        let sentiment = SentimentScore(
            symbol: symbol,
            score: pick.0,
            summary: pick.1,
            sources: ["NewsAPI", "Twitter", "Reddit"]
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(sentiment)
        }
    }
} 