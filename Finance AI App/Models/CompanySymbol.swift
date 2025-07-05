import Foundation

struct CompanySymbol: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let name: String
    
    static let commonCompanies = [
        // Tech Companies
        CompanySymbol(symbol: "AAPL", name: "Apple Inc."),
        CompanySymbol(symbol: "MSFT", name: "Microsoft Corporation"),
        CompanySymbol(symbol: "GOOGL", name: "Alphabet Inc."),
        CompanySymbol(symbol: "AMZN", name: "Amazon.com Inc."),
        CompanySymbol(symbol: "META", name: "Meta Platforms Inc."),
        CompanySymbol(symbol: "TSLA", name: "Tesla Inc."),
        CompanySymbol(symbol: "NVDA", name: "NVIDIA Corporation"),
        CompanySymbol(symbol: "AMD", name: "Advanced Micro Devices"),
        CompanySymbol(symbol: "INTC", name: "Intel Corporation"),
        CompanySymbol(symbol: "CRM", name: "Salesforce Inc."),
        
        // Financial Companies
        CompanySymbol(symbol: "JPM", name: "JPMorgan Chase & Co."),
        CompanySymbol(symbol: "BAC", name: "Bank of America Corp."),
        CompanySymbol(symbol: "WFC", name: "Wells Fargo & Co."),
        CompanySymbol(symbol: "V", name: "Visa Inc."),
        CompanySymbol(symbol: "MA", name: "Mastercard Inc."),
        
        // Consumer Companies
        CompanySymbol(symbol: "WMT", name: "Walmart Inc."),
        CompanySymbol(symbol: "TGT", name: "Target Corporation"),
        CompanySymbol(symbol: "COST", name: "Costco Wholesale"),
        CompanySymbol(symbol: "HD", name: "Home Depot Inc."),
        CompanySymbol(symbol: "MCD", name: "McDonald's Corporation"),
        
        // Entertainment & Media
        CompanySymbol(symbol: "DIS", name: "The Walt Disney Company"),
        CompanySymbol(symbol: "NFLX", name: "Netflix Inc."),
        CompanySymbol(symbol: "CMCSA", name: "Comcast Corporation"),
        CompanySymbol(symbol: "SONY", name: "Sony Group Corporation"),
        
        // Healthcare & Pharma
        CompanySymbol(symbol: "JNJ", name: "Johnson & Johnson"),
        CompanySymbol(symbol: "PFE", name: "Pfizer Inc."),
        CompanySymbol(symbol: "UNH", name: "UnitedHealth Group"),
        
        // Consumer Goods
        CompanySymbol(symbol: "KO", name: "The Coca-Cola Company"),
        CompanySymbol(symbol: "PEP", name: "PepsiCo Inc."),
        CompanySymbol(symbol: "NKE", name: "Nike Inc."),
        CompanySymbol(symbol: "SBUX", name: "Starbucks Corporation"),
        
        // Industrial & Auto
        CompanySymbol(symbol: "F", name: "Ford Motor Company"),
        CompanySymbol(symbol: "GM", name: "General Motors Company"),
        CompanySymbol(symbol: "BA", name: "Boeing Company"),
        
        // Energy & Utilities
        CompanySymbol(symbol: "XOM", name: "Exxon Mobil Corporation"),
        CompanySymbol(symbol: "CVX", name: "Chevron Corporation")
    ]
} 