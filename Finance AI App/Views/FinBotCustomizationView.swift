import SwiftUI

struct FinBotCustomizationView: View {
    @ObservedObject var userStore: UserStore
    @State private var finBotSettings: FinBotSettings
    @State private var showingPreview = false
    @State private var previewMessage = ""
    
    init(userStore: UserStore) {
        self.userStore = userStore
        self._finBotSettings = State(initialValue: userStore.currentUser?.finBotSettings ?? FinBotSettings.default())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                finBotSettings.theme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Bot Name Customization
                        nameCustomizationSection
                        
                        // Mood Selection
                        moodSelectionSection
                        
                        // Voice Selection
                        voiceSelectionSection
                        
                        // Theme Selection
                        themeSelectionSection
                        
                        // Response Settings
                        responseSettingsSection
                        
                        // Preview Section
                        previewSection
                        
                        // Save Button
                        saveButton
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Customize FinBot")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(finBotSettings.theme.botGradient)
                    .frame(width: 100, height: 100)
                    .shadow(radius: 8)
                
                Image(systemName: finBotSettings.voice.avatar)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            Text(finBotSettings.customName.isEmpty ? "FinBot" : finBotSettings.customName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your Personal Finance Assistant")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var nameCustomizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Bot Name", systemImage: "textformat")
                .font(.headline)
                .foregroundColor(finBotSettings.theme.accentColor)
            
            TextField("Enter custom name (optional)", text: $finBotSettings.customName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
            
            Text("Leave empty to use 'FinBot'")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var moodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Personality Mood", systemImage: "theatermasks")
                .font(.headline)
                .foregroundColor(finBotSettings.theme.accentColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(FinBotMood.allCases) { mood in
                    MoodCard(
                        mood: mood,
                        isSelected: finBotSettings.mood == mood,
                        accentColor: finBotSettings.theme.accentColor
                    ) {
                        finBotSettings.mood = mood
                        generatePreview()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var voiceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Voice Style", systemImage: "waveform")
                .font(.headline)
                .foregroundColor(finBotSettings.theme.accentColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(FinBotVoice.allCases) { voice in
                    VoiceCard(
                        voice: voice,
                        isSelected: finBotSettings.voice == voice,
                        accentColor: finBotSettings.theme.accentColor
                    ) {
                        finBotSettings.voice = voice
                        generatePreview()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Chat Theme", systemImage: "paintbrush")
                .font(.headline)
                .foregroundColor(finBotSettings.theme.accentColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(FinBotTheme.allCases) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: finBotSettings.theme == theme
                    ) {
                        finBotSettings.theme = theme
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var responseSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Response Settings", systemImage: "gearshape")
                .font(.headline)
                .foregroundColor(finBotSettings.theme.accentColor)
            
            VStack(spacing: 12) {
                Toggle("Use Emojis", isOn: $finBotSettings.useEmojis)
                    .onChange(of: finBotSettings.useEmojis) { _ in generatePreview() }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Response Length")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Response Length", selection: $finBotSettings.responseLength) {
                        ForEach(FinBotSettings.ResponseLength.allCases) { length in
                            VStack(alignment: .leading) {
                                Text(length.rawValue)
                                    .font(.body)
                                Text(length.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(length)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: finBotSettings.responseLength) { _ in generatePreview() }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Preview", systemImage: "eye")
                .font(.headline)
                .foregroundColor(finBotSettings.theme.accentColor)
            
            if !previewMessage.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    // Bot avatar
                    ZStack {
                        Circle()
                            .fill(finBotSettings.theme.botGradient)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: finBotSettings.voice.avatar)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                    
                    // Message bubble
                    VStack(alignment: .leading, spacing: 4) {
                        Text(previewMessage)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(finBotSettings.theme.botGradient)
                            .foregroundColor(.white)
                            .clipShape(ChatBubbleShape(isUser: false))
                        
                        Text(finBotSettings.customName.isEmpty ? "FinBot" : finBotSettings.customName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Button("Generate Preview") {
                generatePreview()
            }
            .foregroundColor(finBotSettings.theme.accentColor)
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .onAppear {
            generatePreview()
        }
    }
    
    private var saveButton: some View {
        Button(action: saveSettings) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Customizations")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .font(.title3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(finBotSettings.theme.userGradient)
            .cornerRadius(16)
        }
    }
    
    private func generatePreview() {
        previewMessage = finBotSettings.getGreeting()
    }
    
    private func saveSettings() {
        userStore.updateFinBotSettings(finBotSettings)
    }
}

// MARK: - Supporting Views

struct MoodCard: View {
    let mood: FinBotMood
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.title)
                
                Text(mood.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(mood.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? accentColor.opacity(0.2) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VoiceCard: View {
    let voice: FinBotVoice
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: voice.avatar)
                    .font(.title2)
                    .foregroundColor(isSelected ? accentColor : .primary)
                
                Text(voice.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(voice.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? accentColor.opacity(0.2) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemeCard: View {
    let theme: FinBotTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(theme.botGradient)
                        .frame(width: 16, height: 16)
                    
                    Circle()
                        .fill(theme.userGradient)
                        .frame(width: 16, height: 16)
                    
                    Circle()
                        .fill(theme.backgroundGradient)
                        .frame(width: 16, height: 16)
                }
                
                Text(theme.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(theme.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? theme.accentColor.opacity(0.2) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



struct FinBotCustomizationView_Previews: PreviewProvider {
    static var previews: some View {
        FinBotCustomizationView(userStore: UserStore())
    }
}
