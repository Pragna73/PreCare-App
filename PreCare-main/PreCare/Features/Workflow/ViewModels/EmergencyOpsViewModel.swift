import Foundation
import Combine

@MainActor
final class EmergencyOpsViewModel: ObservableObject {
    @Published var userID = SessionStore.shared.userID
    @Published var locationCoordinates = "12.97,77.59"
    @Published var severity = "high"
    @Published var isLoading = false
    @Published var output = ""
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func syncUserID() {
        if userID.isEmpty {
            userID = SessionStore.shared.userID
        }
    }

    func triggerEmergency() async {
        guard !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "User ID is required"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            output = try await apiClient.triggerEmergency(userID: userID, location: locationCoordinates, severity: severity)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
