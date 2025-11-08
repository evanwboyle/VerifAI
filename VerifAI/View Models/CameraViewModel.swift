import Foundation
import Combine
import UIKit

class CameraViewModel: ObservableObject {
    @Published var messageInput: String = ""
    @Published var chatMessages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedImage: UIImage? = nil
    @Published var showImagePicker: Bool = false

    func sendMessage() {
        guard !messageInput.trimmingCharacters(in: .whitespaces).isEmpty || selectedImage != nil else {
            return
        }

        let userMessage = messageInput
        messageInput = ""

        // Add user message to chat
        chatMessages.append(ChatMessage(id: UUID(), role: .user, content: userMessage, timestamp: Date()))

        isLoading = true
        errorMessage = nil

        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        selectedImage = nil

        GrokService.shared.callGrokAPI(message: userMessage, imageData: imageData) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false

                switch result {
                case .success(let response):
                    self?.chatMessages.append(ChatMessage(id: UUID(), role: .assistant, content: response, timestamp: Date()))
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func clearChat() {
        chatMessages.removeAll()
        errorMessage = nil
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    enum MessageRole: Equatable {
        case user
        case assistant
    }
}
