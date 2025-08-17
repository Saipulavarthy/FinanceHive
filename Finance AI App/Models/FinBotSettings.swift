import Foundation
import SwiftUI

// MARK: - FinBot Personality Settings

enum FinBotMood: String, Codable, CaseIterable, Identifiable {
    case professional = "Professional"
    case friendly = "Friendly"
    case enthusiastic = "Enthusiastic"
    case supportive = "Supportive"
    case witty = "Witty"
    case motivational = "Motivational"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .professional:
            return "Formal, precise, and business-like responses"
        case .friendly:
            return "Warm, casual, and approachable communication"
        case .enthusiastic:
            return "Energetic, exciting, and upbeat personality"
        case .supportive:
            return "Encouraging, understanding, and empathetic"
        case .witty:
            return "Clever, humorous, and entertaining responses"
        case .motivational:
            return "Inspiring, goal-focused, and empowering"
        }
    }
    
    var emoji: String {
        switch self {
        case .professional: return "💼"
        case .friendly: return "😊"
        case .enthusiastic: return "🎉"
        case .supportive: return "🤗"
        case .witty: return "😄"
        case .motivational: return "💪"
        }
    }
    
    var responseStyle: String {
        switch self {
        case .professional:
            return "Provide clear, concise financial guidance with professional terminology."
        case .friendly:
            return "Use warm, casual language and relate to the user's everyday experiences."
        case .enthusiastic:
            return "Show excitement about financial progress and use energetic language with emojis."
        case .supportive:
            return "Be understanding and encouraging, especially during financial challenges."
        case .witty:
            return "Include clever observations and light humor while staying helpful."
        case .motivational:
            return "Focus on empowerment, goals, and inspiring financial success."
        }
    }
}

enum FinBotVoice: String, Codable, CaseIterable, Identifiable {
    case neutral = "Neutral"
    case masculine = "Masculine"
    case feminine = "Feminine"
    case youthful = "Youthful"
    case mature = "Mature"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .neutral:
            return "Balanced and gender-neutral tone"
        case .masculine:
            return "Confident and assertive communication"
        case .feminine:
            return "Nurturing and intuitive responses"
        case .youthful:
            return "Fresh, modern, and trendy language"
        case .mature:
            return "Wise, experienced, and thoughtful"
        }
    }
    
    var avatar: String {
        switch self {
        case .neutral: return "brain.head.profile"
        case .masculine: return "person.fill"
        case .feminine: return "person.crop.circle.fill"
        case .youthful: return "face.smiling"
        case .mature: return "graduationcap.fill"
        }
    }
}

enum FinBotTheme: String, Codable, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case ocean = "Ocean"
    case sunset = "Sunset"
    case forest = "Forest"
    case royal = "Royal"
    case minimal = "Minimal"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .light: return "Clean white and gray theme"
        case .dark: return "Dark mode with black backgrounds"
        case .ocean: return "Blue and teal ocean vibes"
        case .sunset: return "Orange and pink sunset colors"
        case .forest: return "Green and earth tones"
        case .royal: return "Purple and gold elegance"
        case .minimal: return "Ultra-clean monochrome design"
        }
    }
    
    var botGradient: LinearGradient {
        switch self {
        case .light:
            return LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            return LinearGradient(colors: [Color.black.opacity(0.8), Color.gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .ocean:
            return LinearGradient(colors: [Color.blue, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sunset:
            return LinearGradient(colors: [Color.orange, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forest:
            return LinearGradient(colors: [Color.green, Color.mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .royal:
            return LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .minimal:
            return LinearGradient(colors: [Color.black, Color.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var userGradient: LinearGradient {
        switch self {
        case .light:
            return LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
        case .dark:
            return LinearGradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        case .ocean:
            return LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing)
        case .sunset:
            return LinearGradient(colors: [Color.red, Color.orange], startPoint: .leading, endPoint: .trailing)
        case .forest:
            return LinearGradient(colors: [Color.green.opacity(0.8), Color.teal], startPoint: .leading, endPoint: .trailing)
        case .royal:
            return LinearGradient(colors: [Color.purple, Color.pink], startPoint: .leading, endPoint: .trailing)
        case .minimal:
            return LinearGradient(colors: [Color.primary, Color.secondary], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    var backgroundGradient: LinearGradient {
        switch self {
        case .light:
            return LinearGradient(colors: [Color.white, Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        case .dark:
            return LinearGradient(colors: [Color.black, Color.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
        case .ocean:
            return LinearGradient(colors: [Color.blue.opacity(0.1), Color.teal.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        case .sunset:
            return LinearGradient(colors: [Color.orange.opacity(0.1), Color.pink.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        case .forest:
            return LinearGradient(colors: [Color.green.opacity(0.1), Color.mint.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        case .royal:
            return LinearGradient(colors: [Color.purple.opacity(0.1), Color.indigo.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        case .minimal:
            return LinearGradient(colors: [Color.clear, Color.gray.opacity(0.05)], startPoint: .top, endPoint: .bottom)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .light: return .blue
        case .dark: return .purple
        case .ocean: return .teal
        case .sunset: return .orange
        case .forest: return .green
        case .royal: return .purple
        case .minimal: return .primary
        }
    }
}

// MARK: - FinBot Settings Model

struct FinBotSettings: Codable {
    var mood: FinBotMood
    var voice: FinBotVoice
    var theme: FinBotTheme
    var customName: String
    var useEmojis: Bool
    var responseLength: ResponseLength
    var createdAt: Date
    var updatedAt: Date
    
    enum ResponseLength: String, Codable, CaseIterable, Identifiable {
        case brief = "Brief"
        case detailed = "Detailed"
        case comprehensive = "Comprehensive"
        
        var id: String { self.rawValue }
        
        var description: String {
            switch self {
            case .brief: return "Short, to-the-point responses"
            case .detailed: return "Balanced explanations with context"
            case .comprehensive: return "Thorough, educational responses"
            }
        }
        
        var maxWords: Int {
            switch self {
            case .brief: return 30
            case .detailed: return 100
            case .comprehensive: return 200
            }
        }
    }
    
    static func `default`() -> FinBotSettings {
        FinBotSettings(
            mood: .friendly,
            voice: .neutral,
            theme: .ocean,
            customName: "FinBot",
            useEmojis: true,
            responseLength: .detailed,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // Generate personality prompt for AI responses
    func personalityPrompt() -> String {
        let basePrompt = """
        You are \(customName), a personal finance assistant with these characteristics:
        
        Mood: \(mood.responseStyle)
        Voice: \(voice.description)
        Response Length: \(responseLength.description) (aim for ~\(responseLength.maxWords) words)
        Emojis: \(useEmojis ? "Use relevant emojis to enhance communication" : "Avoid using emojis")
        
        Always maintain this personality while providing accurate financial advice.
        """
        
        return basePrompt
    }
    
    // Get greeting message based on personality
    func getGreeting() -> String {
        let name = customName.isEmpty ? "FinBot" : customName
        
        switch mood {
        case .professional:
            return "Good day! I'm \(name), your financial advisor. How may I assist you with your finances today?"
        case .friendly:
            return useEmojis ? "Hey there! 😊 I'm \(name), your friendly finance buddy. What's on your mind?" : "Hi! I'm \(name), your friendly finance assistant. What can I help you with?"
        case .enthusiastic:
            return useEmojis ? "Hello! 🎉 I'm \(name) and I'm excited to help you crush your financial goals! What's up?" : "Hello! I'm \(name) and I'm excited to help you with your finances! What's up?"
        case .supportive:
            return useEmojis ? "Hi there! 🤗 I'm \(name), and I'm here to support you on your financial journey. How can I help?" : "Hi! I'm \(name), and I'm here to support you with your finances. How can I help?"
        case .witty:
            return useEmojis ? "Well hello! 😄 I'm \(name), your financially savvy sidekick. Ready to make some money moves?" : "Hello! I'm \(name), your financially savvy assistant. Ready to talk money?"
        case .motivational:
            return useEmojis ? "Hey champion! 💪 I'm \(name), here to help you build wealth and achieve financial freedom! What's your goal today?" : "Hello! I'm \(name), here to help you achieve financial success! What's your goal today?"
        }
    }
}
