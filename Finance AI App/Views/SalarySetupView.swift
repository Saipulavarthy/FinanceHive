import SwiftUI

struct SalarySetupView: View {
    @ObservedObject var userStore: UserStore
    @Binding var isPresented: Bool
    
    @State private var salaryAmount = ""
    @State private var selectedFrequency: PayFrequency = .monthly
    @State private var nextPayDate = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var skipSalarySetup = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Set Up Automatic Salary")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("Never forget to log your income again! We'll automatically credit your salary based on your pay schedule.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 24) {
                            // Salary Amount
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Salary Amount")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                TextField("Enter your salary amount", text: $salaryAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.title2)
                                    .padding(.vertical, 8)
                            }
                            
                            // Pay Frequency
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Pay Frequency")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Picker("Pay Frequency", selection: $selectedFrequency) {
                                    ForEach(PayFrequency.allCases) { frequency in
                                        VStack(alignment: .leading) {
                                            Text(frequency.rawValue)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            Text(frequency.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .tag(frequency)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 8)
                            }
                            
                            // Next Pay Date
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("Next Pay Date")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                DatePicker(
                                    "Next Pay Date",
                                    selection: $nextPayDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            Button(action: setupSalary) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Set Up Automatic Salary")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            .disabled(salaryAmount.isEmpty)
                            .opacity(salaryAmount.isEmpty ? 0.6 : 1.0)
                            
                            Button(action: { isPresented = false }) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                    Text("Skip for Now")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.secondary)
                                .font(.body)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("Salary Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Skip") { isPresented = false })
            .alert("Setup Status", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func setupSalary() {
        guard let amount = Double(salaryAmount), amount > 0 else {
            alertMessage = "Please enter a valid salary amount."
            showingAlert = true
            return
        }
        
        let schedule = SalarySchedule(
            amount: amount,
            frequency: selectedFrequency,
            nextPayDate: nextPayDate
        )
        
        userStore.setSalarySchedule(schedule)
        
        alertMessage = "✅ Automatic salary setup complete!\n\nYour \(selectedFrequency.rawValue.lowercased()) salary of $\(String(format: "%.2f", amount)) will be automatically credited starting \(formatDate(nextPayDate))."
        showingAlert = true
        
        // Dismiss after showing success message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPresented = false
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct SalarySetupView_Previews: PreviewProvider {
    static var previews: some View {
        SalarySetupView(
            userStore: UserStore(),
            isPresented: .constant(true)
        )
    }
}
