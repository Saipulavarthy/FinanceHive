import Foundation

struct YahooQuoteResponse: Codable {
    let quoteResponse: QuoteResponse
}

struct QuoteResponse: Codable {
    let result: [YahooQuote]
    let error: String?
}

struct YahooQuote: Codable {
    let symbol: String
    let regularMarketPrice: Double?
    let regularMarketTime: Int?
    let marketCap: Double?
    let regularMarketChange: Double?
    let regularMarketChangePercent: Double?
    let regularMarketVolume: Int?
}

@MainActor
class StockStore: ObservableObject {
    @Published var currentStock: Stock?
    @Published var historicalData: [Stock.HistoricalData] = []
    @Published var watchlist: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://api.example.com/v1"  // Replace with actual API URL
    
    func fetchStockData(symbol: String) async {
        isLoading = true
        errorMessage = nil
        let url = URL(string: "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(symbol)")!
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(YahooQuoteResponse.self, from: data)
            guard let quote = decoded.quoteResponse.result.first else {
                errorMessage = "No data found for symbol."
                isLoading = false
                return
            }
            let companyName = CompanySymbol.commonCompanies.first(where: { $0.symbol == quote.symbol })?.name ?? quote.symbol
            currentStock = Stock(
                symbol: quote.symbol,
                companyName: companyName,
                currentPrice: quote.regularMarketPrice ?? 0,
                priceChange: quote.regularMarketChange ?? 0,
                percentChange: quote.regularMarketChangePercent ?? 0,
                marketCap: quote.marketCap ?? 0,
                volume: quote.regularMarketVolume ?? 0
            )
            await fetchHistoricalData(symbol: symbol, range: .year)
        } catch {
            errorMessage = "Failed to fetch stock data"
        }
        isLoading = false
    }
    
    func fetchHistoricalData(symbol: String, range: TimeRange) async {
        // Generate simulated historical data
        var data: [Stock.HistoricalData] = []
        let calendar = Calendar.current
        let endDate = Date()
        
        let numberOfPoints: Int
        let dateComponent: Calendar.Component
        let interval: Int
        
        switch range {
        case .year:
            numberOfPoints = 12  // Monthly points for a year
            dateComponent = .month
            interval = -1
        case .twoYears:
            numberOfPoints = 24  // Monthly points for 2 years
            dateComponent = .month
            interval = -1
        case .threeYears:
            numberOfPoints = 36  // Monthly points for 3 years
            dateComponent = .month
            interval = -1
        case .fiveYears:
            numberOfPoints = 60  // Monthly points for 5 years
            dateComponent = .month
            interval = -1
        case .tenYears:
            numberOfPoints = 120  // Monthly points for 10 years
            dateComponent = .month
            interval = -1
        }
        
        var currentDate = endDate
        let basePrice = Double.random(in: 100...1000)
        
        for _ in 0..<numberOfPoints {
            let price = basePrice + Double.random(in: -100...100)
            data.append(Stock.HistoricalData(date: currentDate, price: price))
            
            if let newDate = calendar.date(byAdding: dateComponent, value: interval, to: currentDate) {
                currentDate = newDate
            }
        }
        
        historicalData = data.reversed()
    }
    
    func toggleWatchlist(symbol: String) {
        if watchlist.contains(symbol) {
            watchlist.removeAll { $0 == symbol }
        } else {
            watchlist.append(symbol)
        }
    }
}

// MARK: - Yahoo Finance API Response Models
struct YahooFinanceResponse: Codable {
    let chart: ChartResponse
}

struct ChartResponse: Codable {
    let result: [ChartResult]
    let error: String?
}

struct ChartResult: Codable {
    let meta: MetaData?
    let timestamp: [Int]?
    let indicators: Indicators
}

struct MetaData: Codable {
    let symbol: String
    let previousClose: Double?
    let regularMarketPrice: Double?
    let marketCap: Int64?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case previousClose = "chartPreviousClose"
        case regularMarketPrice
        case marketCap
    }
}

struct Indicators: Codable {
    let quote: [Quote]
}

struct Quote: Codable {
    let close: [Double]
    let volume: [Int64]
    
    enum CodingKeys: String, CodingKey {
        case close = "close"
        case volume = "volume"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let closeOptional = try container.decodeIfPresent([Double?].self, forKey: .close) ?? []
        let volumeOptional = try container.decodeIfPresent([Int64?].self, forKey: .volume) ?? []
        
        self.close = closeOptional.compactMap { $0 }
        self.volume = volumeOptional.compactMap { $0 }
    }
} 
