import Foundation

enum MessageSender: String, Codable {
    case user = "user"
    case bot = "bot"
    
    var displayName: String {
        switch self {
        case .user:
            return "You"
        case .bot:
            return "FinBot"
        }
    }
    
    var isUser: Bool {
        return self == .user
    }
}

struct Message: Identifiable, Codable {
    let id = UUID()
    let content: String
    let sender: MessageSender
    let timestamp: Date
    
    // Computed property for backward compatibility
    var isUser: Bool {
        return sender.isUser
    }
    
    // Convenience initializers
    init(content: String, sender: MessageSender, timestamp: Date = Date()) {
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
    }
    
    init(content: String, isUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.sender = isUser ? .user : .bot
        self.timestamp = timestamp
    }
    
    static func assistant(_ content: String) -> Message {
        Message(content: content, sender: .bot, timestamp: Date())
    }
    
    static func user(_ content: String) -> Message {
        Message(content: content, sender: .user, timestamp: Date())
    }
    
    static func bot(_ content: String) -> Message {
        Message(content: content, sender: .bot, timestamp: Date())
    }
} 