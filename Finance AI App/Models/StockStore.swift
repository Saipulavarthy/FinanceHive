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
        
        // Clean and validate symbol
        let cleanSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanSymbol.isEmpty else {
            errorMessage = "Invalid symbol."
            isLoading = false
            return
        }
        
        // Try Yahoo Finance first with improved error handling
        do {
            try await fetchFromYahoo(symbol: cleanSymbol)
            errorMessage = nil
        } catch {
            print("Yahoo Finance failed with error: \(error)")
            // Try Stooq fallback
            do {
                try await fetchViaStooqFallback(symbol: cleanSymbol)
                errorMessage = nil
            } catch {
                print("Stooq fallback failed with error: \(error)")
                errorMessage = "Failed to fetch stock data for \(cleanSymbol). Please check the symbol and try again."
            }
        }
        isLoading = false
    }
    
    private func fetchFromYahoo(symbol: String) async throws {
        guard let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v7/finance/quote?symbols=\(encodedSymbol)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://finance.yahoo.com", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 10.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("Yahoo Finance HTTP Status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Debug: Print response data
        if let responseString = String(data: data, encoding: .utf8) {
            print("Yahoo Response: \(String(responseString.prefix(500)))")
        }
        
        // Parse JSON response
        let decoded = try JSONDecoder().decode(YahooQuoteResponse.self, from: data)
        
        guard let quote = decoded.quoteResponse.result.first,
              let price = quote.regularMarketPrice else {
            throw URLError(.cannotParseResponse)
        }
        
        let companyName = CompanySymbol.commonCompanies.first(where: { $0.symbol == quote.symbol })?.name ?? quote.symbol
        
        currentStock = Stock(
            symbol: quote.symbol,
            companyName: companyName,
            currentPrice: price,
            priceChange: quote.regularMarketChange ?? 0,
            percentChange: quote.regularMarketChangePercent ?? 0,
            marketCap: quote.marketCap ?? 0,
            volume: quote.regularMarketVolume ?? 0
        )
        
        await fetchHistoricalData(symbol: symbol, range: .year)
    }
    
    private func fetchViaStooqFallback(symbol: String) async throws {
        print("Attempting Stooq fallback for symbol: \(symbol)")
        
        // Try multiple variants with better error handling
        let variants = [
            symbol.lowercased() + ".us",
            symbol.uppercased() + ".US",
            symbol.lowercased(),
            symbol.uppercased()
        ]
        
        for variant in variants {
            print("Trying Stooq variant: \(variant)")
            
            // Try stooq.com first
            if let data = try? await fetchStooqCSV(symbolVariant: variant, baseURL: "https://stooq.com") {
                await createStockFromStooqData(data: data, originalSymbol: symbol)
                return
            }
            
            // Then try stooq.pl
            if let data = try? await fetchStooqCSV(symbolVariant: variant, baseURL: "https://stooq.pl") {
                await createStockFromStooqData(data: data, originalSymbol: symbol)
                return
            }
        }
        
        throw URLError(.cannotLoadFromNetwork)
    }
    
    private func createStockFromStooqData(data: (symbol: String, close: Double, volume: Int), originalSymbol: String) async {
        let companyName = CompanySymbol.commonCompanies.first(where: {
            $0.symbol.uppercased() == originalSymbol.uppercased()
        })?.name ?? originalSymbol.uppercased()
        
        currentStock = Stock(
            symbol: originalSymbol.uppercased(),
            companyName: companyName,
            currentPrice: data.close,
            priceChange: 0,
            percentChange: 0,
            marketCap: 0,
            volume: data.volume
        )
        
        await fetchHistoricalData(symbol: originalSymbol.uppercased(), range: .year)
    }
    
    private func fetchStooqCSV(symbolVariant: String, baseURL: String) async throws -> (symbol: String, close: Double, volume: Int)? {
        guard let encodedSymbol = symbolVariant.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        // Try minimal CSV format first
        if let url = URL(string: "\(baseURL)/q/l/?s=\(encodedSymbol)&i=d") {
            do {
                var request = URLRequest(url: url)
                request.setValue("text/plain", forHTTPHeaderField: "Accept")
                request.timeoutInterval = 10.0
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                if let csv = String(data: data, encoding: .utf8) {
                    print("Stooq CSV Response for \(symbolVariant): \(String(csv.prefix(200)))")
                    
                    let lines = csv.split(whereSeparator: { $0.isNewline }).map(String.init)
                    
                    if lines.count >= 2 {
                        // Skip header line, find first data line
                        for line in lines.dropFirst() {
                            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedLine.isEmpty {
                                let fields = trimmedLine.split(separator: ",").map {
                                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                
                                if fields.count >= 8 &&
                                   fields[6].uppercased() != "N/D" &&
                                   !fields[6].isEmpty,
                                   let closePrice = Double(fields[6]),
                                   closePrice > 0 {
                                    let volume = Int(fields[7]) ?? 0
                                    return (symbol: fields[0].uppercased(), close: closePrice, volume: volume)
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error fetching from \(url): \(error)")
                // Continue to next format
            }
        }
        
        // Try headered CSV format as fallback
        if let url = URL(string: "\(baseURL)/q/l/?s=\(encodedSymbol)&f=sd2t2ohlcv&h&e=csv") {
            do {
                var request = URLRequest(url: url)
                request.setValue("text/csv", forHTTPHeaderField: "Accept")
                request.timeoutInterval = 10.0
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                if let csv = String(data: data, encoding: .utf8) {
                    let lines = csv.split(whereSeparator: { $0.isNewline }).map(String.init)
                    
                    if lines.count >= 2 {
                        for line in lines.dropFirst() {
                            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedLine.isEmpty {
                                let fields = trimmedLine.split(separator: ",").map {
                                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                
                                if fields.count >= 8 &&
                                   fields[6].uppercased() != "N/D" &&
                                   !fields[6].isEmpty,
                                   let closePrice = Double(fields[6]),
                                   closePrice > 0 {
                                    let volume = Int(fields[7]) ?? 0
                                    return (symbol: fields[0].uppercased(), close: closePrice, volume: volume)
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error fetching headered CSV from \(url): \(error)")
            }
        }
        
        return nil
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
        let basePrice = currentStock?.currentPrice ?? Double.random(in: 100...1000)
        
        for _ in 0..<numberOfPoints {
            let price = basePrice + Double.random(in: -100...100)
            data.append(Stock.HistoricalData(date: currentDate, price: max(price, 1.0))) // Ensure positive price
            
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
