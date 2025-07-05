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