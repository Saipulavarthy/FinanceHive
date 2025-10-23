import Foundation

struct OpenAIService {
    static let shared = OpenAIService()
    
    private let apiKey: String = {
        // Try to load from environment variable first
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Fallback to UserDefaults for development
        if let storedKey = UserDefaults.standard.string(forKey: "OpenAI_API_Key"), !storedKey.isEmpty {
            return storedKey
        }
        
        // Return placeholder if no key found
        return "YOUR_OPENAI_API_KEY_HERE"
    }()
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {}
    
    func generateResponse(for prompt: String) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw OpenAIError.invalidAPIKey
        }
        
        let request = OpenAIRequest(
            model: "gpt-3.5-turbo",
            messages: [
                OpenAIMessage(role: "system", content: """
                You are FinBot, a helpful and friendly personal finance assistant. 
                Your responses should be:
                - Concise and helpful
                - Finance-focused
                - Encouraging and supportive
                - Include relevant emojis
                - Actionable when possible
                
                Keep responses under 150 words unless detailed analysis is requested.
                """),
                OpenAIMessage(role: "user", content: prompt)
            ],
            maxTokens: 150,
            temperature: 0.7
        )
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw OpenAIError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        do {
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return openAIResponse.choices.first?.message.content ?? "I'm sorry, I couldn't generate a response."
        } catch {
            throw OpenAIError.decodingError
        }
    }
}

// MARK: - Data Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// MARK: - Error Handling
enum OpenAIError: Error, LocalizedError {
    case invalidAPIKey
    case invalidURL
    case encodingError
    case invalidResponse
    case httpError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid or missing OpenAI API key"
        case .invalidURL:
            return "Invalid OpenAI API URL"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode OpenAI response"
        }
    }
}
