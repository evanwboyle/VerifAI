import Foundation

class GrokService {
    static let shared = GrokService()

    private let apiEndpoint = "https://api.x.ai/v1/chat/completions"
    private let model = "grok-4"

    /// Retrieves the Grok API key from secrets.plist
    private func getAPIKey() throws -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let contents = NSDictionary(contentsOfFile: path) as? [String: Any],
              let apiKey = contents["GROK_API_KEY"] as? String,
              !apiKey.isEmpty else {
            throw GrokServiceError.missingAPIKey
        }
        return apiKey
    }

    /// Makes a chat completion request to the Grok API
    func callGrokAPI(message: String, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let apiKey = try getAPIKey()

            guard let url = URL(string: apiEndpoint) else {
                completion(.failure(GrokServiceError.invalidURL))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "model": model,
                "messages": [
                    ["role": "user", "content": message]
                ]
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                completion(.failure(error))
                return
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(GrokServiceError.noDataReceived))
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else {
                        completion(.failure(GrokServiceError.failedToParseResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
}

enum GrokServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case noDataReceived
    case failedToParseResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Grok API key not found in secrets.plist"
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .noDataReceived:
            return "No data received from Grok API"
        case .failedToParseResponse:
            return "Failed to parse Grok API response"
        }
    }
}
