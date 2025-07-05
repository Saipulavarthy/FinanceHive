import Foundation

enum RiskLevel: String, CaseIterable, Codable {
    case low, medium, high
}

enum InvestmentGoal: String, CaseIterable, Codable {
    case growth, income, preservation
}

struct UserProfile: Codable {
    var name: String
    var email: String
    var riskLevel: RiskLevel
    var investmentGoal: InvestmentGoal
    var preferredSectors: [String]
    var isBeginner: Bool?
    var createdAt: Date
    var updatedAt: Date
    // Add more fields as needed
    
    static func `default`() -> UserProfile {
        UserProfile(
            name: "",
            email: "",
            riskLevel: .medium,
            investmentGoal: .growth,
            preferredSectors: [],
            isBeginner: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
} 