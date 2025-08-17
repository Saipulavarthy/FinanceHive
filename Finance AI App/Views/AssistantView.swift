import SwiftUI

struct AssistantView: View {
    @StateObject private var assistantStore: AssistantStore
    @ObservedObject var userStore: UserStore
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    private var finBotSettings: FinBotSettings {
        userStore.currentUser?.finBotSettings ?? FinBotSettings.default()
    }
    
    init(transactionStore: TransactionStore, stockStore: StockStore, userStore: UserStore) {
        self.userStore = userStore
        _assistantStore = StateObject(wrappedValue: AssistantStore(transactionStore: transactionStore, stockStore: stockStore, userStore: userStore))
    }
    
    var body: some View {
        ZStack {
            // Themed background gradient
            finBotSettings.theme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // FinBot Header with glass effect
                HStack {
                    ZStack {
                        Circle()
                            .fill(finBotSettings.theme.botGradient)
                            .frame(width: 35, height: 35)
                        
                        Image(systemName: finBotSettings.voice.avatar)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    
                    Text(finBotSettings.customName.isEmpty ? "FinBot" : finBotSettings.customName)
                        .font(.title2)
                        .bold()
                        .foregroundColor(finBotSettings.theme.accentColor)
                    
                    Spacer()
                    
                    // Customization button
                    NavigationLink(destination: FinBotCustomizationView(userStore: userStore)) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(finBotSettings.theme.accentColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    Color(.systemBackground)
                        .opacity(0.9)
                        .blur(radius: 3)
                )
                
                // Rest of the content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(assistantStore.messages) { message in
                                MessageBubble(message: message, finBotSettings: finBotSettings)
                            }
                            
                            if assistantStore.isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: assistantStore.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(assistantStore.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                
                // Input area with glass effect
                HStack {
                    TextField("Ask \(finBotSettings.customName.isEmpty ? "FinBot" : finBotSettings.customName) anything...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(finBotSettings.theme.accentColor)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(
                    Color(.systemBackground)
                        .opacity(0.8)
                        .blur(radius: 3)
                )
            }
        }
        .navigationTitle("FinBot")
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        assistantStore.sendMessage(trimmedMessage)
        messageText = ""
        isFocused = false
    }
}

struct MessageBubble: View {
    let message: Message
    let finBotSettings: FinBotSettings
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                if !message.isUser {
                    // Bot Avatar with themed design
                    ZStack {
                        Circle()
                            .fill(finBotSettings.theme.botGradient)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: finBotSettings.voice.avatar)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                if message.isUser { Spacer() }
                
                VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                    // Message content with themed colors
                    Text(message.content)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            message.isUser ?
                            finBotSettings.theme.userGradient :
                            finBotSettings.theme.botGradient
                        )
                        .foregroundColor(.white)
                        .clipShape(ChatBubbleShape(isUser: message.isUser))
                    
                    // Timestamp and sender
                    HStack(spacing: 4) {
                        if !message.isUser {
                            Text(finBotSettings.customName.isEmpty ? "FinBot" : finBotSettings.customName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                        
                        Text(formatTimestamp(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, message.isUser ? 8 : 0)
                }
                
                if !message.isUser { Spacer() }
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

struct ChatBubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isUser ? 
                [.topLeft, .topRight, .bottomLeft] : 
                [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: 18, height: 18)
        )
        return Path(path.cgPath)
    }
}

struct TypingIndicator: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack {
            Text("Typing" + String(repeating: ".", count: dotCount))
                .padding()
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(16)
            Spacer()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
} 