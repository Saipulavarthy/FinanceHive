import SwiftUI

struct PortfolioView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("Link your brokerage account to view your portfolio here.")
                    .multilineTextAlignment(.center)
                Button("Link Brokerage (Mock)") {
                    // Future: Link brokerage logic
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Portfolio")
        }
    }
} 