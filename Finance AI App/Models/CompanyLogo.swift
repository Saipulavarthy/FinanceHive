import SwiftUI

struct CompanyLogo {
    static func systemImage(for symbol: String) -> String {
        switch symbol {
        // Tech Companies
        case "AAPL": return "apple.logo"
        case "MSFT": return "windows.logo"
        case "GOOGL": return "g.circle.fill"
        case "AMZN": return "cart.fill"
        case "META": return "message.circle.fill"
        case "TSLA": return "bolt.car.fill"
        case "NVDA", "AMD", "INTC": return "cpu.fill"
        case "CRM": return "cloud.fill"
        
        // Financial Companies
        case "JPM", "BAC", "WFC": return "building.columns.fill"
        case "V", "MA": return "creditcard.fill"
        
        // Consumer Companies
        case "WMT", "TGT", "COST": return "cart.circle.fill"
        case "HD": return "hammer.fill"
        case "MCD": return "fork.knife.circle.fill"
        
        // Entertainment & Media
        case "DIS": return "sparkles"
        case "NFLX": return "play.tv.fill"
        case "CMCSA", "SONY": return "tv.fill"
        
        // Healthcare & Pharma
        case "JNJ", "PFE": return "cross.case.fill"
        case "UNH": return "heart.circle.fill"
        
        // Consumer Goods
        case "KO", "PEP": return "cup.and.saucer.fill"
        case "NKE": return "figure.run.circle.fill"
        case "SBUX": return "cup.and.saucer.fill"
        
        // Industrial & Auto
        case "F", "GM": return "car.fill"
        case "BA": return "airplane"
        
        // Energy & Utilities
        case "XOM", "CVX": return "flame.fill"
        
        default: return "dollarsign.circle.fill"
        }
    }
    
    static func color(for symbol: String) -> Color {
        switch symbol {
        // Tech Companies
        case "AAPL": return .gray
        case "MSFT": return .blue
        case "GOOGL": return .red
        case "AMZN": return .orange
        case "META": return .blue
        case "TSLA": return .red
        case "NVDA": return .green
        case "AMD": return .red
        case "INTC": return .blue
        case "CRM": return .blue
        
        // Financial Companies
        case "JPM", "V": return .blue
        case "BAC": return .red
        case "WFC": return .red
        case "MA": return .orange
        
        // Consumer Companies
        case "WMT": return .blue
        case "TGT": return .red
        case "COST": return .blue
        case "HD": return .orange
        case "MCD": return .yellow
        
        // Entertainment & Media
        case "DIS": return .purple
        case "NFLX": return .red
        case "CMCSA": return .blue
        case "SONY": return .blue
        
        // Healthcare & Pharma
        case "JNJ": return .red
        case "PFE": return .blue
        case "UNH": return .blue
        
        // Consumer Goods
        case "KO": return .red
        case "PEP": return .blue
        case "NKE": return .black
        case "SBUX": return .green
        
        // Industrial & Auto
        case "F": return .blue
        case "GM": return .blue
        case "BA": return .blue
        
        // Energy & Utilities
        case "XOM": return .red
        case "CVX": return .blue
        
        default: return .blue
        }
    }
} 