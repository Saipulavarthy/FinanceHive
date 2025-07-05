import SwiftUI

struct AssistantView: View {
    @StateObject private var assistantStore: AssistantStore
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    init(transactionStore: TransactionStore, stockStore: StockStore) {
        _assistantStore = StateObject(wrappedValue: AssistantStore(transactionStore: transactionStore, stockStore: stockStore))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1),
                    Color.pink.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // FinBot Header with glass effect
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    Text("FinBot")
                        .font(.title2)
                        .bold()
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    Color(.systemBackground)
                        .opacity(0.8)
                        .blur(radius: 3)
                )
                
                // Rest of the content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(assistantStore.messages) { message in
                                MessageBubble(message: message)
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
                    TextField("Ask FinBot anything...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !message.isUser {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding()
                .background(
                    message.isUser ?
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemBackground).opacity(0.9)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isUser { Spacer() }
        }
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