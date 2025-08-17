import SwiftUI

struct ProfileView: View {
    @ObservedObject var userStore: UserStore
    @State private var showEdit = false
    @State private var notificationsEnabled: Bool = true
    
    var userInitials: String {
        let name = userStore.currentUser?.name ?? "User"
        let comps = name.split(separator: " ")
        let initials = comps.prefix(2).map { String($0.prefix(1)) }.joined()
        return initials.isEmpty ? "U" : initials
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.10)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Colorful header with initials
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                            .shadow(radius: 6)
                        Text(userInitials)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                    }
                    Text(userStore.currentUser?.name ?? "User")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    Text(userStore.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 12)
                
                Form {
                    Section {
                        Toggle(isOn: $notificationsEnabled) {
                            Label("Notifications", systemImage: notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                    }
                    
                    Section(header: Label("Security", systemImage: "lock.shield").foregroundColor(.red)) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Biometric Authentication")
                            Spacer()
                            if SecurityManager.shared.isBiometricAvailable() {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Text("Not Available")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button(action: {
                            // Export data securely
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Data")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            // Import data securely
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import Data")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            // Show secure deletion confirmation
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete All Data")
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    Section(header: Label("Income & Salary", systemImage: "creditcard.fill").foregroundColor(.green)) {
                        NavigationLink(destination: SalaryManagementView(userStore: userStore)) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                VStack(alignment: .leading) {
                                    Text("Automatic Salary")
                                        .fontWeight(.medium)
                                    if let schedule = userStore.currentUser?.salarySchedule {
                                        Text("$\(String(format: "%.0f", schedule.amount)) \(schedule.frequency.rawValue.lowercased())")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Not set up")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .foregroundColor(.green)
                        }
                    }
                    
                    Section(header: Label("AI Assistant", systemImage: "brain.head.profile").foregroundColor(.purple)) {
                        NavigationLink(destination: FinBotCustomizationView(userStore: userStore)) {
                            HStack {
                                Image(systemName: "theatermasks.fill")
                                VStack(alignment: .leading) {
                                    Text("Customize FinBot")
                                        .fontWeight(.medium)
                                    if let finBotSettings = userStore.currentUser?.finBotSettings {
                                        Text("\(finBotSettings.mood.emoji) \(finBotSettings.mood.rawValue) • \(finBotSettings.theme.rawValue)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Personality, voice & theme")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .foregroundColor(.purple)
                        }
                        
                        NavigationLink(destination: SmartFinanceAssistantView(
                            budgetAdjuster: BudgetAdjuster(transactionStore: TransactionStore(), userStore: userStore),
                            reminderManager: SmartReminderManager(transactionStore: TransactionStore(), userStore: userStore),
                            userStore: userStore
                        )) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                VStack(alignment: .leading) {
                                    Text("AI Budget & Reminders")
                                        .fontWeight(.medium)
                                    Text("Smart budget adjustments & bill reminders")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .foregroundColor(.purple)
                        }
                    }
                    
                    Section(header: Label("Siri & Voice", systemImage: "mic.circle").foregroundColor(.orange)) {
                        NavigationLink(destination: SiriShortcutsView()) {
                            HStack {
                                Image(systemName: "waveform")
                                Text("Siri Shortcuts")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    
                    Section(header: Label("Profile", systemImage: "person.crop.circle").foregroundColor(.blue)) {
                        Button(action: { showEdit = true }) {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                Text("Edit Profile")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.purple)
                        }
                    }
                }
                .background(Color.clear)
                .cornerRadius(16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                Spacer()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            NavigationView {
                ProfileEditView(userStore: userStore)
            }
        }
        .onAppear {
            notificationsEnabled = userStore.currentUser?.notificationsEnabled ?? true
        }
        .onChange(of: notificationsEnabled) { newValue in
            if var user = userStore.currentUser {
                user.notificationsEnabled = newValue
                userStore.currentUser = user
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileView(userStore: UserStore())
    }
} 