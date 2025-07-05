import SwiftUI
import Charts

struct StockView: View {
    @StateObject private var stockStore = StockStore()
    @State private var searchText = ""
    @State private var selectedTimeRange: TimeRange = .year
    // Prediction and sentiment state
    @State private var prediction: StockPrediction?
    @State private var sentiment: SentimentScore?
    @State private var showDisclaimer = true
    @EnvironmentObject var userStore: UserStore
    @State private var showingShareSheet = false
    @State private var shareText = ""
    
    var body: some View {
        ZStack {
            // Background
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: 100)
                    .opacity(0.6)
                
                Spacer()
            }
            
            // Main content
            VStack {
                SearchBar(text: $searchText) { symbol in
                    Task {
                        await stockStore.fetchStockData(symbol: symbol)
                        StockPredictionService.fetchPrediction(for: symbol, userProfile: userStore.currentUser?.userProfile) { pred in
                            prediction = pred
                        }
                        StockPredictionService.fetchSentiment(for: symbol) { sent in
                            sentiment = sent
                        }
                    }
                }
                
                if stockStore.isLoading {
                    ProgressView()
                        .tint(.blue)
                } else if let error = stockStore.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else if let stock = stockStore.currentStock {
                    ScrollView {
                        VStack(spacing: 16) {
                            if showDisclaimer {
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                    Text("Stock price predictions are for informational purposes only and do not constitute financial advice. Markets are volatile and predictions are uncertain.")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(action: { showDisclaimer = false }) {
                                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                                    }
                                }
                                .padding(8)
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(10)
                            }
                            StockInfoCard(stock: stock)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground).opacity(0.9))
                                        .shadow(color: .blue.opacity(0.1), radius: 8)
                                )
                            if let sentiment = sentiment {
                                SentimentView(sentiment: sentiment)
                            }
                            TimeRangeSelector(selectedRange: $selectedTimeRange)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground).opacity(0.9))
                                        .shadow(color: .blue.opacity(0.1), radius: 8)
                                )
                            StockPredictionChart(
                                historicalData: stockStore.historicalData,
                                prediction: prediction
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground).opacity(0.9))
                                    .shadow(color: .blue.opacity(0.1), radius: 8)
                            )
                            WatchlistButton(
                                symbol: stock.symbol,
                                isWatchlisted: stockStore.watchlist.contains(stock.symbol),
                                action: { stockStore.toggleWatchlist(symbol: stock.symbol) }
                            )
                            if let prediction = prediction {
                                Button(action: {
                                    shareText = "Stock prediction for \(prediction.symbol):\n" + prediction.predictedPrices.map { "\($0.date.formatted(date: .abbreviated, time: .omitted)): $\(String(format: "%.2f", $0.price)) (Confidence: \(Int($0.confidence*100))%)" }.joined(separator: "\n")
                                    showingShareSheet = true
                                }) {
                                    Label("Share Prediction", systemImage: "square.and.arrow.up")
                                }
                                .padding(.bottom, 4)
                                .sheet(isPresented: $showingShareSheet) {
                                    ActivityView(activityItems: [shareText])
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                if !stockStore.watchlist.isEmpty {
                    WatchlistView(symbols: stockStore.watchlist)
                }
            }
        }
        .navigationTitle("Stocks")
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1),
                    Color.pink.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onChange(of: selectedTimeRange) { newRange in
            if let symbol = stockStore.currentStock?.symbol {
                Task {
                    await stockStore.fetchHistoricalData(symbol: symbol, range: newRange)
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSubmit: (String) -> Void
    @State private var showingSuggestions = false
    @State private var filteredCompanies: [CompanySymbol] = []
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search company name or symbol", text: $text, onCommit: {
                    // Only allow submit if text matches a known symbol
                    if let match = CompanySymbol.commonCompanies.first(where: { $0.symbol.lowercased() == text.lowercased() }) {
                        onSubmit(match.symbol)
                    } else if let match = CompanySymbol.commonCompanies.first(where: { $0.name.lowercased() == text.lowercased() }) {
                        onSubmit(match.symbol)
                    } else {
                        // Optionally show an error or ignore
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .onChange(of: text) { newValue in
                    filterCompanies(query: newValue)
                    showingSuggestions = !newValue.isEmpty
                }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        showingSuggestions = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            
            if showingSuggestions && !filteredCompanies.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(filteredCompanies) { company in
                            Button(action: {
                                text = company.symbol
                                onSubmit(company.symbol)
                                showingSuggestions = false
                            }) {
                                HStack {
                                    Image(systemName: CompanyLogo.systemImage(for: company.symbol))
                                        .foregroundColor(CompanyLogo.color(for: company.symbol))
                                        .font(.title2)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text(company.name)
                                            .foregroundColor(.primary)
                                        Text(company.symbol)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            
                            if company.id != filteredCompanies.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                )
                .frame(maxHeight: 200)
                .padding(.horizontal)
            }
        }
    }
    
    private func filterCompanies(query: String) {
        if query.isEmpty {
            filteredCompanies = []
        } else {
            filteredCompanies = CompanySymbol.commonCompanies.filter {
                $0.name.lowercased().contains(query.lowercased()) ||
                $0.symbol.lowercased().contains(query.lowercased())
            }
        }
    }
}

struct StockInfoCard: View {
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: CompanyLogo.systemImage(for: stock.symbol))
                    .foregroundColor(CompanyLogo.color(for: stock.symbol))
                    .font(.title)
                    .frame(width: 40)
                
                Text(stock.companyName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("$\(String(format: "%.2f", stock.currentPrice))")
                    .font(.title)
                    .foregroundColor(.primary)
                    .bold()
                
                Text(String(format: "%.2f%%", stock.percentChange))
                    .font(.headline)
                    .foregroundColor(stock.priceChange >= 0 ? .green : .red)
                    .bold()
            }
            
            HStack {
                InfoItem(title: "Market Cap", value: formatMarketCap(stock.marketCap))
                InfoItem(title: "Volume", value: formatVolume(stock.volume))
            }
        }
        .padding()
    }
    
    private func formatMarketCap(_ value: Double) -> String {
        // Format market cap in billions/millions
        return "$\(String(format: "%.2f", value / 1_000_000_000))B"
    }
    
    private func formatVolume(_ value: Int) -> String {
        return "\(value / 1_000_000)M"
    }
}

struct InfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        HStack {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(range.rawValue) {
                    selectedRange = range
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedRange == range ? 
                              Color.blue.opacity(0.9) : 
                              Color.blue.opacity(0.1))
                )
                .foregroundColor(selectedRange == range ? .white : .blue)
                .bold()
            }
        }
        .padding()
    }
}

struct StockChart: View {
    let data: [Stock.HistoricalData]
    @Binding var selectedRange: TimeRange
    
    private var chartYDomain: ClosedRange<Double> {
        guard !data.isEmpty else { return 0...100 }
        
        let prices = data.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 100
        let padding = (maxPrice - minPrice) * 0.1
        
        return (minPrice - padding)...(maxPrice + padding)
    }
    
    private var xAxisStride: Calendar.Component {
        switch selectedRange {
        case .year:
            return .month
        case .twoYears:
            return .month // Show every 3 months
        case .threeYears:
            return .month // Show every 6 months
        case .fiveYears:
            return .year
        case .tenYears:
            return .year // Show every 2 years
        }
    }
    
    private var xAxisValues: [Date] {
        guard !data.isEmpty else { return [] }
        
        let calendar = Calendar.current
        var dates: [Date] = []
        let startDate = data.first?.date ?? Date()
        let endDate = data.last?.date ?? Date()
        
        switch selectedRange {
        case .year:
            // Show all months
            dates = calendar.generateDates(
                from: startDate,
                to: endDate,
                by: .month
            )
        case .twoYears:
            // Show every 3 months
            dates = calendar.generateDates(
                from: startDate,
                to: endDate,
                by: .month,
                interval: 3
            )
        case .threeYears:
            // Show every 6 months
            dates = calendar.generateDates(
                from: startDate,
                to: endDate,
                by: .month,
                interval: 6
            )
        case .fiveYears:
            // Show every year
            dates = calendar.generateDates(
                from: startDate,
                to: endDate,
                by: .year
            )
        case .tenYears:
            // Show every 2 years
            dates = calendar.generateDates(
                from: startDate,
                to: endDate,
                by: .year,
                interval: 2
            )
        }
        return dates
    }
    
    private var dateFormat: Date.FormatStyle {
        switch selectedRange {
        case .year:
            return .dateTime.month(.abbreviated)
        case .twoYears, .threeYears:
            return .dateTime.month(.abbreviated).year()
        case .fiveYears, .tenYears:
            return .dateTime.year()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if data.isEmpty {
                Text("No historical data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: 200)
            } else {
                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Price", point.price)
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: chartYDomain)
                .chartXAxis {
                    AxisMarks(values: xAxisValues) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: dateFormat)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text("$\(String(format: "%.2f", price))")
                            }
                        }
                    }
                }
                .foregroundStyle(.blue.gradient)
            }
        }
        .padding()
    }
}

// Add this extension to help generate dates
extension Calendar {
    func generateDates(
        from startDate: Date,
        to endDate: Date,
        by component: Calendar.Component,
        interval: Int = 1
    ) -> [Date] {
        var dates: [Date] = []
        var date = startDate
        
        while date <= endDate {
            dates.append(date)
            guard let newDate = self.date(
                byAdding: component,
                value: interval,
                to: date
            ) else { break }
            date = newDate
        }
        
        return dates
    }
}

struct WatchlistButton: View {
    let symbol: String
    let isWatchlisted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(
                isWatchlisted ? "Remove from Watchlist" : "Add to Watchlist",
                systemImage: isWatchlisted ? "star.fill" : "star"
            )
            .foregroundColor(isWatchlisted ? .yellow : .blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isWatchlisted ? Color.yellow : Color.blue, lineWidth: 2)
            )
        }
    }
}

struct WatchlistView: View {
    let symbols: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Watchlist")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(symbols, id: \.self) { symbol in
                        HStack {
                            Image(systemName: CompanyLogo.systemImage(for: symbol))
                                .foregroundColor(CompanyLogo.color(for: symbol))
                            Text(symbol)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct SentimentView: View {
    let sentiment: SentimentScore
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Market Sentiment:")
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text(sentimentEmoji)
                    .font(.title2)
            }
            Text(sentiment.summary)
                .font(.footnote)
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                ForEach(sentiment.sources, id: \.self) { src in
                    Text(src)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
    private var sentimentEmoji: String {
        if sentiment.score > 0.3 { return "😃" }
        if sentiment.score < -0.3 { return "😟" }
        return "😐"
    }
}

struct StockPredictionChart: View {
    let historicalData: [Stock.HistoricalData]
    let prediction: StockPrediction?
    @State private var showingExplanation: PredictedPrice?
    var body: some View {
        VStack(alignment: .leading) {
            Text("Price Chart & Prediction")
                .font(.headline)
            if historicalData.isEmpty && (prediction?.predictedPrices.isEmpty ?? true) {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: 200)
            } else {
                Chart {
                    ForEach(historicalData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Price", point.price)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue)
                    }
                    if let prediction = prediction {
                        ForEach(prediction.predictedPrices) { pred in
                            LineMark(
                                x: .value("Date", pred.date),
                                y: .value("Predicted", pred.price)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.orange)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        }
                    }
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text("$\(String(format: "%.2f", price))")
                            }
                        }
                    }
                }
                if let prediction = prediction {
                    ForEach(prediction.predictedPrices) { pred in
                        HStack {
                            Text(pred.date, format: .dateTime.month().day())
                            Spacer()
                            ProgressView(value: pred.confidence)
                                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                .frame(width: 80)
                            Text("\(Int(pred.confidence*100))%")
                                .font(.caption)
                            Button(action: { showingExplanation = pred }) {
                                Image(systemName: "info.circle")
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(.top, 8)
        .sheet(item: $showingExplanation) { pred in
            VStack(spacing: 20) {
                Text("Prediction Explanation")
                    .font(.headline)
                Text(pred.explanation)
                    .padding()
                Button("Close") { showingExplanation = nil }
            }
            .padding()
        }
    }
}

// Add a CommunityTab placeholder
struct CommunityTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Community features coming soon! Discuss predictions, share insights, and connect with other investors.")
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("Community")
    }
}

// Add ActivityView for sharing
import UIKit
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 