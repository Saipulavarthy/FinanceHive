import SwiftUI
import AVFoundation
import Vision
import CoreData

struct ScanReceiptView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isShowingCamera = false
    @State private var scannedText = ""
    @State private var extractedAmount: Double?
    @State private var extractedMerchant = ""
    @State private var extractedCategory: Transaction.Category = .other
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Camera preview placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                        .frame(height: 300)
                    
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Tap to scan receipt")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    isShowingCamera = true
                }
                
                // Scan results
                if !scannedText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scanned Text:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView {
                            Text(scannedText)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 100)
                        
                        if let amount = extractedAmount {
                            HStack {
                                Text("Amount: $\(String(format: "%.2f", amount))")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                        }
                        
                        if !extractedMerchant.isEmpty {
                            HStack {
                                Text("Merchant: \(extractedMerchant)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                        
                        // Category selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category:")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Category", selection: $extractedCategory) {
                                ForEach(Transaction.Category.allCases, id: \..self) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.vertical, 8)

                        Button(action: saveExpense) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Expense")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(extractedAmount == nil)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingCamera) {
                CameraView { image in
                    processImage(image)
                }
            }
            .alert("Scan Result", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        guard let cgImage = image.cgImage else {
            alertMessage = "Failed to process image"
            showingAlert = true
            isProcessing = false
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Text recognition failed: \(error.localizedDescription)"
                    showingAlert = true
                    isProcessing = false
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    alertMessage = "No text found in image"
                    showingAlert = true
                    isProcessing = false
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                scannedText = recognizedStrings.joined(separator: "\n")
                extractExpenseData(from: scannedText)
                isProcessing = false
            }
        }
        
        request.recognitionLevel = .accurate
        
        do {
            try requestHandler.perform([request])
        } catch {
            DispatchQueue.main.async {
                alertMessage = "Failed to process image: \(error.localizedDescription)"
                showingAlert = true
                isProcessing = false
            }
        }
    }
    
    private func extractExpenseData(from text: String) {
        // Extract amount using regex
        let amountPattern = #"\$([0-9]+(?:\.[0-9]{2})?)"#
        if let regex = try? NSRegularExpression(pattern: amountPattern) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               let amountRange = Range(match.range(at: 1), in: text) {
                let amountString = String(text[amountRange])
                extractedAmount = Double(amountString)
            }
        }
        
        // Extract merchant (simplified - look for common patterns)
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let lowercased = line.lowercased()
            if lowercased.contains("total") || lowercased.contains("amount") {
                continue
            }
            if line.count > 3 && line.count < 50 {
                extractedMerchant = line.trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        
        // Auto-categorize based on merchant name
        if !extractedMerchant.isEmpty {
            extractedCategory = Transaction.category(for: extractedMerchant)
        }
    }
    
    private func saveExpense() {
        guard let amount = extractedAmount else { return }
        
        let expense = NSEntityDescription.insertNewObject(forEntityName: "RecurringExpense", into: viewContext)
        expense.setValue(amount, forKey: "amount")
        expense.setValue(extractedCategory.rawValue, forKey: "category")
        expense.setValue("Scanned receipt from \(extractedMerchant)", forKey: "note")
        expense.setValue(Date(), forKey: "date")
        expense.setValue(false, forKey: "isRecurring")
        expense.setValue(nil as String?, forKey: "repeatInterval")
        
        do {
            try viewContext.save()
            alertMessage = "Expense saved successfully!"
            showingAlert = true
            
            // Reset form
            scannedText = ""
            extractedAmount = nil
            extractedMerchant = ""
            extractedCategory = .other
        } catch {
            alertMessage = "Failed to save expense: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        
        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ScanReceiptView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
