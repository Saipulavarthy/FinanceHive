import Foundation
import Speech
import AVFoundation

@MainActor
class VoiceExpenseService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var parsedExpense: ParsedExpense?
    @Published var permissionStatus: PermissionStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    enum PermissionStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }
    
    override init() {
        super.init()
        requestPermissions()
    }
    
    // MARK: - Permission Handling
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.permissionStatus = .authorized
                case .denied:
                    self?.permissionStatus = .denied
                case .restricted:
                    self?.permissionStatus = .restricted
                case .notDetermined:
                    self?.permissionStatus = .notDetermined
                @unknown default:
                    self?.permissionStatus = .notDetermined
                }
            }
        }
    }
    
    // MARK: - Voice Recording
    
    func startRecording() {
        guard permissionStatus == .authorized else {
            errorMessage = "Speech recognition permission not granted"
            return
        }
        
        // Reset previous session
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session setup failed"
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create speech recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get audio input node
        let inputNode = audioEngine.inputNode
        
        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                    self?.parseExpenseFromText(result.bestTranscription.formattedString)
                }
                
                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }
        
        // Configure audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            transcribedText = ""
            parsedExpense = nil
            errorMessage = nil
        } catch {
            errorMessage = "Audio engine failed to start"
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
    
    // MARK: - Text Parsing
    
    private func parseExpenseFromText(_ text: String) {
        let lowercased = text.lowercased()
        
        // Extract amount
        let amount = extractAmount(from: lowercased)
        
        // Extract merchant
        let merchant = extractMerchant(from: lowercased)
        
        // Extract description/notes
        let description = extractDescription(from: lowercased)
        
        // Auto-categorize based on merchant
        let category = Transaction.category(for: merchant)
        
        if amount > 0 {
            parsedExpense = ParsedExpense(
                amount: amount,
                merchant: merchant,
                description: description,
                category: category,
                originalText: text
            )
        }
    }
    
    private func extractAmount(from text: String) -> Double {
        // Patterns for different amount formats
        let patterns = [
            #"(?:spent|paid|cost|costs|for)\s*\$?([0-9]+(?:\.[0-9]{2})?)"#,
            #"\$([0-9]+(?:\.[0-9]{2})?)"#,
            #"([0-9]+(?:\.[0-9]{2})?)\s*(?:dollars?|bucks?)"#,
            #"(?:twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety)\s*(?:dollars?|bucks?)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   let amountRange = Range(match.range(at: 1), in: text) {
                    let amountString = String(text[amountRange])
                    if let amount = Double(amountString) {
                        return amount
                    }
                }
            }
        }
        
        // Handle spelled-out numbers
        return parseSpelledOutAmount(from: text)
    }
    
    private func parseSpelledOutAmount(from text: String) -> Double {
        let numberWords = [
            "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
            "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20,
            "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70,
            "eighty": 80, "ninety": 90, "hundred": 100
        ]
        
        for (word, value) in numberWords {
            if text.contains(word) {
                return Double(value)
            }
        }
        
        return 0
    }
    
    private func extractMerchant(from text: String) -> String {
        // Patterns to find merchant names
        let patterns = [
            #"(?:at|from)\s+([a-zA-Z\s&'-]+?)(?:\s+for|\s+\$|\s*$)"#,
            #"([a-zA-Z\s&'-]+?)\s+(?:for|cost|costs)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   let merchantRange = Range(match.range(at: 1), in: text) {
                    let merchant = String(text[merchantRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !merchant.isEmpty && merchant.count > 2 {
                        return merchant.capitalized
                    }
                }
            }
        }
        
        return "Voice Entry"
    }
    
    private func extractDescription(from text: String) -> String {
        // Extract context or item descriptions
        let patterns = [
            #"(?:for|bought|purchasing)\s+([a-zA-Z\s]+?)(?:\s+at|\s+\$|\s*$)"#,
            #"([a-zA-Z\s]+?)\s+(?:at|from)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   let descRange = Range(match.range(at: 1), in: text) {
                    let description = String(text[descRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !description.isEmpty && description.count > 2 {
                        return description.capitalized
                    }
                }
            }
        }
        
        return "Voice expense entry"
    }
}

// MARK: - Data Models

struct ParsedExpense {
    let amount: Double
    let merchant: String
    let description: String
    let category: Transaction.Category
    let originalText: String
}
