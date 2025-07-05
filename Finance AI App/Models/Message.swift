import Foundation

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let date: Date
    
    static func assistant(_ content: String) -> Message {
        Message(content: content, isUser: false, date: Date())
    }
    
    static func user(_ content: String) -> Message {
        Message(content: content, isUser: true, date: Date())
    }
} 