import Foundation
import os.log
import UIKit

class GrokService {
    static let shared = GrokService()
    private let log = OSLog(subsystem: "com.verifai.grokservice", category: "network")

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

    /// Resize image to fit within maxSize, maintaining aspect ratio
    private func resizeImage(_ data: Data, maxSize: CGFloat = 640) -> Data? {

        if let image = UIImage(data: data) {
            let width = image.size.width
            let height = image.size.height
            let maxDimension = max(width, height)
            if maxDimension <= maxSize {
                os_log("Image resizing not needed. Original size: %.0fx%.0f", log: self.log, type: .info, width, height)
                return data // No resizing needed
            }
            let scale = maxSize / maxDimension
            let newSize = CGSize(width: width * scale, height: height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resizedImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            os_log("Image resized. Original size: %.0fx%.0f, Output size: %.0fx%.0f", log: self.log, type: .info, width, height, newSize.width, newSize.height)
            return resizedImage.jpegData(compressionQuality: 0.9)
        }
        return data // Fallback: return original data if UIKit not available
    }

    /// Makes a chat completion request to the Grok API, supporting optional image data
    func callGrokAPI(message: String, imageData: Data? = nil, systemPrompt: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let apiKey = try getAPIKey()

            guard let url = URL(string: apiEndpoint) else {
                os_log("Invalid API endpoint URL: %@", log: self.log, type: .error, apiEndpoint)
                completion(.failure(GrokServiceError.invalidURL))
                return
            }

            os_log("Starting request to endpoint: %@", log: self.log, type: .info, url.path)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            var messages: [[String: Any]] = []
            if let systemPrompt = systemPrompt {
                messages.append(["role": "system", "content": systemPrompt])
            }
            if let imageData = imageData {
                let resizedData = resizeImage(imageData) ?? imageData
                let base64Image = resizedData.base64EncodedString()
                let imageContent: [String: Any] = [
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)",
                        "detail": "medium"
                    ]
                ]
                let textContent: [String: Any] = [
                    "type": "text",
                    "text": message
                ]
                let userMessage: [String: Any] = [
                    "role": "user",
                    "content": [imageContent, textContent]
                ]
                messages.append(userMessage)
            } else {
                messages.append(["role": "user", "content": message])
            }
            let body: [String: Any] = [
                "model": model,
                "messages": messages
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                os_log("Failed to serialize request body: %@", log: self.log, type: .error, String(describing: error))
                completion(.failure(error))
                return
            }

            os_log("Built request: %@", log: self.log, type: .debug, request.debugDescription)
            // Custom httpBody logging: redact base64 image if present
            if let httpBody = request.httpBody, var httpBodyString = String(data: httpBody, encoding: .utf8) {
                do {
                    let regex = try NSRegularExpression(pattern: "data:image/jpeg;base64,[^\"]*", options: [])
                    let range = NSRange(location: 0, length: httpBodyString.utf16.count)
                    httpBodyString = regex.stringByReplacingMatches(in: httpBodyString, options: [], range: range, withTemplate: "data:image/jpeg;base64,[image]")
                } catch {
                    os_log("Regex error: %@", log: self.log, type: .error, String(describing: error))
                }
                os_log("Request httpBody: %@", log: self.log, type: .debug, httpBodyString)
            } else {
                os_log("Request httpBody: Not decodable to string", log: self.log, type: .debug)
            }
            os_log("Request headers: %@", log: self.log, type: .debug, request.allHTTPHeaderFields?.description ?? "None")
            os_log("Request URL: %@", log: self.log, type: .debug, request.url?.absoluteString ?? "None")

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    os_log("Network error: %@", log: self.log, type: .error, String(describing: error))
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    os_log("No data received from Grok API", log: self.log, type: .error)
                    completion(.failure(GrokServiceError.noDataReceived))
                    return
                }

                os_log("Received data: %@", log: self.log, type: .debug, String(data: data, encoding: .utf8) ?? "Not decodable to string")

                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    os_log("HTTP error: %d", log: self.log, type: .error, httpResponse.statusCode)
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else {
                        os_log("Failed to parse Grok API response", log: self.log, type: .error)
                        completion(.failure(GrokServiceError.failedToParseResponse))
                    }
                } catch {
                    os_log("JSON parsing error: %@", log: self.log, type: .error, String(describing: error))
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            os_log("API key error: %@", log: self.log, type: .error, String(describing: error))
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
