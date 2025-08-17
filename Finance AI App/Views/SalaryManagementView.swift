import SwiftUI

struct SalaryManagementView: View {
    @ObservedObject var userStore: UserStore
    @State private var showingEditSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var salarySchedule: SalarySchedule? {
        userStore.currentUser?.salarySchedule
    }
    
    var body: some View {
        List {
            if let schedule = salarySchedule {
                // Current Salary Schedule Section
                Section(header: Label("Current Salary Schedule", systemImage: "creditcard.fill").foregroundColor(.blue)) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Salary Amount")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(String(format: "%.2f", schedule.amount))")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Pay Frequency")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(schedule.frequency.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Text(schedule.frequency.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "clock.circle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Next Pay Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(schedule.formattedNextPayDate())
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        Spacer()
                        if schedule.daysUntilNextPay() == 0 {
                            Text("Today!")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        } else {
                            Text("\(schedule.daysUntilNextPay()) days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: schedule.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                            .foregroundColor(schedule.isActive ? .green : .orange)
                        VStack(alignment: .leading) {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(schedule.isActive ? "Active" : "Paused")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        Spacer()
                    }
                    
                    if let lastCredited = schedule.lastCreditedDate {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Last Credited")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(lastCredited))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                    }
                }
                
                // Actions Section
                Section {
                    Button(action: { showingEditSheet = true }) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                            Text("Edit Salary Schedule")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: toggleSchedule) {
                        HStack {
                            Image(systemName: schedule.isActive ? "pause.circle.fill" : "play.circle.fill")
                                .foregroundColor(schedule.isActive ? .orange : .green)
                            Text(schedule.isActive ? "Pause Automatic Salary" : "Resume Automatic Salary")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    Button(action: manualCredit) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Credit Salary Now")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    Button(action: removeSchedule) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                            Text("Remove Salary Schedule")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
            } else {
                // No Salary Schedule Section
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Automatic Salary Set Up")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("Set up automatic salary crediting to never forget logging your income again.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingEditSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Set Up Automatic Salary")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Salary Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingEditSheet) {
            SalarySetupView(userStore: userStore, isPresented: $showingEditSheet)
        }
        .alert("Salary Management", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func toggleSchedule() {
        guard let schedule = salarySchedule else { return }
        
        userStore.updateSalarySchedule(isActive: !schedule.isActive)
        
        let status = schedule.isActive ? "paused" : "resumed"
        alertMessage = "Automatic salary has been \(status)."
        showingAlert = true
    }
    
    private func manualCredit() {
        guard let schedule = salarySchedule else { return }
        
        userStore.checkAndCreditSalary()
        
        alertMessage = "Salary of $\(String(format: "%.2f", schedule.amount)) has been credited to your account."
        showingAlert = true
    }
    
    private func removeSchedule() {
        userStore.removeSalarySchedule()
        
        alertMessage = "Automatic salary schedule has been removed. You can set it up again anytime."
        showingAlert = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct SalaryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SalaryManagementView(userStore: UserStore())
        }
    }
}
