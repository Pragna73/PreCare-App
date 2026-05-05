import Foundation
import Combine

@MainActor
final class ChatViewModel: ObservableObject {

    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var isRealtimeConnected = false
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func loadHistory(limit: Int = 20) async {
        isLoading = true
        errorMessage = nil

        do {
            try await refreshHistory(limit: limit)
            isLoading = false
        } catch {
            if messages.isEmpty {
                messages = [ChatMessage(text: "Hi! I'm Maya. How can I help you today?", isUser: false)]
            }
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func connectRealtime() {
        do {
            try apiClient.connectMayaWebSocket(
                onText: { [weak self] text in
                    Task { @MainActor in
                        self?.handleSocketPayload(text)
                    }
                },
                onError: { [weak self] error in
                    Task { @MainActor in
                        self?.isRealtimeConnected = false
                        self?.errorMessage = error
                    }
                }
            )
            isRealtimeConnected = true
        } catch {
            isRealtimeConnected = false
            errorMessage = error.localizedDescription
        }
    }

    func disconnectRealtime() {
        apiClient.disconnectMayaWebSocket()
        isRealtimeConnected = false
    }

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        inputText = ""
        messages.append(ChatMessage(text: trimmed, isUser: true, createdAt: Date()))
        isSending = true
        errorMessage = nil

        if isRealtimeConnected {
            Task {
                do {
                    try await apiClient.sendMayaWebSocketMessage(trimmed)
                    isSending = false
                } catch {
                    isSending = false
                    errorMessage = error.localizedDescription
                }
            }
            return
        }

        Task {
            do {
                let response = try await apiClient.sendMayaMessage(trimmed)
                do {
                    try await refreshHistory(limit: 20)
                } catch {
                    // Fallback to local append if history refresh fails.
                    messages.append(ChatMessage(text: response.reply, isUser: false, createdAt: Date()))
                    if let latestRisk = response.latestRisk, !latestRisk.isEmpty, latestRisk.uppercased() != "N/A" {
                        messages.append(ChatMessage(text: "Latest risk: \(latestRisk)", isUser: false, createdAt: Date()))
                    }
                }
                isSending = false
            } catch {
                isSending = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func refreshHistory(limit: Int) async throws {
        let history: [MayaChatHistoryItem]
        do {
            history = try await apiClient.mayaGroupedChatHistory(limit: max(limit, 100))
        } catch {
            history = try await apiClient.mayaChatHistory(limit: limit)
        }
        let mapped = history.map { ChatMessage(text: $0.message, isUser: $0.isUser, createdAt: $0.createdAt) }
        messages = mapped.isEmpty ? [ChatMessage(text: "Hi! I'm Maya. How can I help you today?", isUser: false)] : mapped
    }

    private func handleSocketPayload(_ payload: String) {
        guard let data = payload.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            messages.append(ChatMessage(text: payload, isUser: false, createdAt: Date()))
            return
        }

        let createdAt: Date = {
            if let raw = APIClient.readString(object, keys: ["created_at", "timestamp", "time"]),
               let parsed = APIClient.parseServerDate(raw) {
                return parsed
            }
            return Date()
        }()

        let isUser: Bool = {
            if let flag = object["is_user"] as? Bool { return flag }
            if let role = APIClient.readString(object, keys: ["role", "sender"]) {
                return role.lowercased() == "user"
            }
            return false
        }()

        if let text = APIClient.readString(object, keys: ["reply", "response", "message", "content", "text"]) {
            if !isUser {
                messages.append(ChatMessage(text: text, isUser: false, createdAt: createdAt))
            }
        }

        if let latestRisk = APIClient.readString(object, keys: ["latest_risk", "latestRisk", "risk"]),
           !latestRisk.isEmpty,
           latestRisk.uppercased() != "N/A" {
            messages.append(ChatMessage(text: "Latest risk: \(latestRisk)", isUser: false, createdAt: createdAt))
        }
    }
}
