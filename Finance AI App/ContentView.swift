//
//  ContentView.swift
//  Finance AI App
//
//  Created by Sai Pulavarthy on 1/15/25.
//

import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @StateObject private var store = TransactionStore()
    @StateObject private var stockStore = StockStore()
    @StateObject private var userStore = UserStore()
    @StateObject private var achievementsStore = AchievementsStore()
    @State private var showBeginnerPrompt = false
    @State private var isAuthenticated = false
    @State private var showingAuthAlert = false
    
    var body: some View {
        Group {
            if !isAuthenticated {
                // Authentication screen
                VStack(spacing: 30) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Finance AI App")
                        .font(.largeTitle.bold())
                    
                    Text("Secure your financial data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: authenticateUser) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Authenticate to Continue")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                .onAppear {
                    authenticateUser()
                }
            } else if userStore.isAuthenticated {
                ZStack {
                    MainTabView(store: store, stockStore: stockStore, userStore: userStore, achievementsStore: achievementsStore)
                        .onAppear {
                            store.setAchievementsStore(achievementsStore)
                            if userStore.currentUser?.userProfile.isBeginner == nil {
                                showBeginnerPrompt = true
                            }
                        }
                        .sheet(isPresented: $showBeginnerPrompt) {
                            BeginnerPromptView(userStore: userStore, isPresented: $showBeginnerPrompt)
                        }
                }
            } else {
                SignUpView(userStore: userStore)
            }
        }
        .alert("Authentication Required", isPresented: $showingAuthAlert) {
            Button("Try Again") {
                authenticateUser()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please authenticate to access your financial data.")
        }
    }
    
    private func authenticateUser() {
        if SecurityManager.shared.isBiometricAvailable() {
            SecurityManager.shared.authenticateWithBiometrics { success in
                if success {
                    isAuthenticated = true
                } else {
                    showingAuthAlert = true
                }
            }
        } else {
            // Fallback for devices without biometrics
            isAuthenticated = true
        }
    }
}

struct MainTabView: View {
    @ObservedObject var store: TransactionStore
    @ObservedObject var stockStore: StockStore
    @ObservedObject var userStore: UserStore
    @ObservedObject var achievementsStore: AchievementsStore
    
    var body: some View {
        TabView {
            NavigationView {
                DashboardView(
                    store: store,
                    userStore: userStore,
                    achievementsStore: achievementsStore,
                    userName: userStore.currentUser?.name ?? ""
                )
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.pie.fill")
            }
            
            NavigationView {
                BudgetView(store: store)
            }
            .tabItem {
                Label("Budgets", systemImage: "dollarsign.circle.fill")
            }
            
            NavigationView {
                StockView()
                    .environmentObject(userStore)
            }
            .tabItem {
                Label("Stocks", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            NavigationView {
                AssistantView(transactionStore: store, stockStore: stockStore)
            }
            .tabItem {
                Label("Assistant", systemImage: "message.circle.fill")
            }
            NavigationView {
                CommunityTab()
            }
            .tabItem {
                Label("Community", systemImage: "person.3.fill")
            }
            NavigationView {
                PortfolioView()
            }
            .tabItem {
                Label("Portfolio", systemImage: "briefcase.fill")
            }
        }
        .background(
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
        )
    }
}

struct BeginnerPromptView: View {
    @ObservedObject var userStore: UserStore
    @Binding var isPresented: Bool
    var body: some View {
        VStack(spacing: 24) {
            Text("Are you new to investing?")
                .font(.title2)
                .bold()
            Text("Beginner mode offers extra guidance, simpler dashboards, and helpful tips.")
                .multilineTextAlignment(.center)
            HStack(spacing: 24) {
                Button("Yes, I'm a beginner") {
                    userStore.setIsBeginner(true)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                Button("No, show me advanced features") {
                    userStore.setIsBeginner(false)
                    isPresented = false
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
