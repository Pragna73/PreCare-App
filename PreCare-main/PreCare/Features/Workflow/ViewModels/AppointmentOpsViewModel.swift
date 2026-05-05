import Foundation
import Combine

@MainActor
final class AppointmentOpsViewModel: ObservableObject {
    @Published var userID = SessionStore.shared.userID
    @Published var preferredDate = "2026-02-20"
    @Published var location = "Bangalore"
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

    func bookAppointment() async {
        guard !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "User ID is required"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            output = try await apiClient.bookAppointment(userID: userID, preferredDate: preferredDate)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func autoBookAppointment() async {
        guard !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "User ID is required"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            output = try await apiClient.autoBookAppointment(userID: userID, location: location)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
