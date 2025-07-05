import SwiftUI

struct ProfileEditView: View {
    @ObservedObject var userStore: UserStore
    @State private var riskLevel: RiskLevel = .medium
    @State private var investmentGoal: InvestmentGoal = .growth
    @State private var preferredSectors: [String] = []
    @State private var availableSectors = ["Technology", "Healthcare", "Finance", "Energy", "Consumer", "Industrial", "Utilities", "Real Estate"]
    @Environment(\.presentationMode) var presentationMode
    
    var userInitials: String {
        let name = userStore.currentUser?.name ?? "User"
        let comps = name.split(separator: " ")
        let initials = comps.prefix(2).map { String($0.prefix(1)) }.joined()
        return initials.isEmpty ? "U" : initials
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.10)]), startPoint: .top, endPoint: .bottom)
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
                    Section(header: Label("Risk Level", systemImage: "exclamationmark.triangle.fill").foregroundColor(.orange)) {
                        Picker("Risk Level", selection: $riskLevel) {
                            ForEach(RiskLevel.allCases, id: \.self) { level in
                                Text(level.rawValue.capitalized).tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    Section(header: Label("Investment Goal", systemImage: "target").foregroundColor(.blue)) {
                        Picker("Goal", selection: $investmentGoal) {
                            ForEach(InvestmentGoal.allCases, id: \.self) { goal in
                                Text(goal.rawValue.capitalized).tag(goal)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    Section(header: Label("Preferred Sectors", systemImage: "star.fill").foregroundColor(.purple)) {
                        ForEach(availableSectors, id: \.self) { sector in
                            MultipleSelectionRow(title: sector, isSelected: preferredSectors.contains(sector)) {
                                withAnimation(.spring()) {
                                    if preferredSectors.contains(sector) {
                                        preferredSectors.removeAll { $0 == sector }
                                    } else {
                                        preferredSectors.append(sector)
                                    }
                                }
                            }
                        }
                    }
                }
                .background(Color.clear)
                .cornerRadius(16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                Button(action: {
                    userStore.updateRiskLevel(riskLevel)
                    userStore.updateInvestmentGoal(investmentGoal)
                    userStore.updatePreferredSectors(preferredSectors)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Save Changes")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = userStore.currentUser {
                riskLevel = user.userProfile.riskLevel
                investmentGoal = user.userProfile.investmentGoal
                preferredSectors = user.userProfile.preferredSectors
            }
        }
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                        .transition(.scale)
                }
            }
            .padding(.vertical, 4)
        }
        .background(Color.white.opacity(isSelected ? 0.15 : 0.05))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        ProfileEditView(userStore: UserStore())
    }
} 