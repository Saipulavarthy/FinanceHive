import SwiftUI

struct AchievementsView: View {
    @ObservedObject var store: AchievementsStore
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(store.achievements) { achievement in
                    VStack {
                        Image(systemName: achievement.icon)
                            .font(.largeTitle)
                            .padding()
                            .background(achievement.isUnlocked ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.1))
                            .clipShape(Circle())
                            .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                        
                        Text(achievement.title)
                            .font(.headline)
                        
                        Text(achievement.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(achievement.isUnlocked ? 1.0 : 0.5)
                }
            }
            .padding()
        }
        .navigationTitle("Badges")
    }
} 