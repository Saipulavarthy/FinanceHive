import SwiftUI

extension Font {
    static func poppins(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Fall back to system font since Poppins isn't included in the app
        return .system(size: size, weight: weight, design: .rounded)
    }
}

struct SignUpView: View {
    @StateObject private var userStore: UserStore
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSignIn = false
    @State private var showingSalarySetup = false
    
    private let gradientColors: [Color] = [
        Color(hex: "FFA726").opacity(0.7),  // Orange
        Color(hex: "FB8C00").opacity(0.7),  // Darker Orange
        Color(hex: "FFA726").opacity(0.7)   // Orange
    ]
    
    init(userStore: UserStore) {
        _userStore = StateObject(wrappedValue: userStore)
    }
    
    var body: some View {
        // ORIGINAL CODE:
        ZStack {
            // Animated gradient background
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .hueRotation(.degrees(isSignIn ? 45 : 0))
                .animation(.easeInOut(duration: 0.5), value: isSignIn)
            
            // Finance-themed background symbols
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<20) { index in
                        Image(systemName: financeSymbols[index % financeSymbols.count])
                            .font(.system(size: CGFloat.random(in: 20...40)))
                            .foregroundColor(.white.opacity(0.1))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                    }
                }
            }
            
            // Main content
            ScrollView {
                VStack(spacing: 25) {
                    // Logo and app name
                    VStack(spacing: 15) {
                        ZStack {
                            // Hexagonal background
                            ForEach(0..<6) { index in
                                HexagonShape()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "FFA726"), Color(hex: "FB8C00")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(Double(index) * 60))
                            }
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 10)
                                    .frame(width: 120, height: 120)
                            )
                            
                            // Honeycomb pattern
                            ZStack {
                                ForEach(0..<3) { row in
                                    HStack(spacing: 8) {
                                        ForEach(0..<2) { col in
                                            HexagonShape()
                                                .fill(LinearGradient(
                                                    colors: [Color(hex: "FFA726").opacity(0.2), Color(hex: "FB8C00").opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                                .frame(width: 20, height: 20)
                                                .offset(x: CGFloat(col * 20), y: CGFloat(row * 15))
                                        }
                                    }
                                }
                            }
                            .offset(x: -20, y: -20)
                            
                            // FinanceHive Logo
                            Image("FinanceHive")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.2), radius: 5)
                        }
                        
                        // App name with modern typography
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Text("FINANCE")
                                    .font(.poppins(32, weight: .black))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("HIVE")
                                    .font(.poppins(32, weight: .black))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "FFA726"), Color(hex: "FB8C00")], // Orange/honey colors
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.white)
                                            .shadow(color: .black.opacity(0.15), radius: 5)
                                    )
                            }
                            
                            Text("Track, analyze, and grow – all at your fingertips.")
                                .font(.poppins(18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "FFA726").opacity(0.3),
                                                    Color(hex: "FB8C00").opacity(0.3)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        }
                    }
                    .padding(.top, 50)
                    
                    // Form card
                    VStack(spacing: 20) {
                        Text(isSignIn ? "Welcome Back!" : "Create Account")
                            .font(.poppins(24, weight: .bold))
                        
                        if !isSignIn {
                            CustomTextField(
                                text: $name,
                                placeholder: "Name",
                                systemImage: "person.fill"
                            )
                        }
                        
                        CustomTextField(
                            text: $email,
                            placeholder: "Email",
                            systemImage: "envelope.fill"
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        
                        CustomSecureField(
                            text: $password,
                            placeholder: "Password",
                            systemImage: "lock.fill"
                        )
                        
                        if !isSignIn {
                            CustomSecureField(
                                text: $confirmPassword,
                                placeholder: "Confirm Password",
                                systemImage: "lock.shield.fill"
                            )
                        }
                        
                        Button(action: isSignIn ? signIn : signUp) {
                            HStack {
                                Image(systemName: isSignIn ? "arrow.right.circle.fill" : "checkmark.circle.fill")
                                Text(isSignIn ? "Sign In" : "Create Account")
                            }
                            .font(.poppins(16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FFA726"), Color(hex: "FB8C00")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 5)
                            )
                        }
                        .disabled(email.isEmpty || password.isEmpty || (!isSignIn && (name.isEmpty || confirmPassword.isEmpty)))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground).opacity(0.95))
                            .shadow(color: Color(hex: "FFA726").opacity(0.2), radius: 10)
                    )
                    .padding(.horizontal)
                    
                    // Toggle button
                    Button(action: { 
                        withAnimation { isSignIn.toggle() }
                    }) {
                        Text(isSignIn ? "Don't have an account? Sign Up" : "Already have an account? Sign In")
                            .font(.poppins(14, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 3)
                    }
                    .padding(.top)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingSalarySetup) {
            SalarySetupView(userStore: userStore, isPresented: $showingSalarySetup)
        }
    }
    
    private let financeSymbols = [
        "dollarsign.circle",
        "chart.line.uptrend.xyaxis",
        "creditcard",
        "building.columns",
        "chart.pie",
        "wallet.pass",
        "banknote",
        "arrow.left.arrow.right",
        "percent",
        "chart.bar"
    ]
    
    private func signUp() {
        guard isValidEmail(email) else {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }
        
        guard password.count >= 8 else {
            alertMessage = "Password must be at least 8 characters long"
            showingAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords don't match"
            showingAlert = true
            return
        }
        
        if userStore.signUp(name: name, email: email, password: password) {
            // Show salary setup after successful sign up
            showingSalarySetup = true
        } else {
            alertMessage = "Email already exists"
            showingAlert = true
        }
    }
    
    private func signIn() {
        if userStore.signIn(email: email, password: password) {
            // Success
        } else {
            alertMessage = "Invalid email or password"
            showingAlert = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// Custom styled text field
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.black) // Force black text
                .background(Color.white) // Force white background
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white) // Force white background
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )
        )
    }
}

// Custom styled secure field
struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
                .frame(width: 20)
            SecureField(placeholder, text: $text)
                .foregroundColor(.black) // Force black text
                .background(Color.white) // Force white background
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white) // Force white background
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )
        )
    }
}

// Add this extension at the bottom of the file for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Add this shape at the bottom of the file
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = min(width, height) / 2
        
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}