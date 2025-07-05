import Foundation

struct Stock: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let companyName: String
    let currentPrice: Double
    let priceChange: Double
    let percentChange: Double
    let marketCap: Double
    let volume: Int
    
    struct HistoricalData: Identifiable {
        let id = UUID()
        let date: Date
        let price: Double
    }
}

enum TimeRange: String, CaseIterable {
    case year = "1Y"
    case twoYears = "2Y"
    case threeYears = "3Y"
    case fiveYears = "5Y"
    case tenYears = "10Y"
    
    var days: Int {
        switch self {
        case .year: return 365
        case .twoYears: return 730
        case .threeYears: return 1095
        case .fiveYears: return 1825
        case .tenYears: return 3650
        }
    }
} 