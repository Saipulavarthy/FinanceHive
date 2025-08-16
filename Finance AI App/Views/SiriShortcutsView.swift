import SwiftUI

struct SiriShortcutsView: View {
    @StateObject private var shortcutsManager = SiriShortcutsManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Voice Commands")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Basic Siri shortcuts are automatically available:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• \"Hey Siri, log my expense\"")
                            Text("• \"Hey Siri, record spending\"")
                            Text("• \"Hey Siri, add transaction\"")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("How to Set Up")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Use the app a few times to log expenses")
                        Text("2. iOS will automatically suggest Siri shortcuts")
                        Text("3. Add shortcuts from iOS Settings > Siri & Search")
                        Text("4. Say your custom phrases to Siri")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                Section(header: Text("Voice Features")) {
                    NavigationLink(destination: Text("Voice Expense Entry")) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Voice Expense Entry")
                                    .font(.headline)
                                Text("Speak to add expenses in-app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: "waveform.path")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Siri Shortcuts")
                                .font(.headline)
                            Text("Available via iOS Settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("✅")
                            .foregroundColor(.green)
                    }
                }
                
                Section(footer: Text("Note: Full Siri integration requires creating custom intents in Xcode. For now, basic voice commands and in-app voice entry are available.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Voice & Siri")
        }
    }
}

#Preview {
    SiriShortcutsView()
}
