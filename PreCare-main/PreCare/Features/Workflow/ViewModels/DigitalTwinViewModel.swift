import Foundation
import Combine

@MainActor
final class DigitalTwinViewModel: ObservableObject {
    @Published var userID = SessionStore.shared.userID
    @Published var age = "24"
    @Published var bpHistory = "130/90,160/100"
    @Published var hemoglobin = "9.2"
    @Published var diabetes = false
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

    func createTwin() async {
        guard !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "User ID is required"
            return
        }

        let ageValue = Int(age) ?? 24
        let hbValue = Double(hemoglobin) ?? 9.2
        let history = bpHistory
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        isLoading = true
        errorMessage = nil
        do {
            output = try await apiClient.createTwin(
                userID: userID,
                age: ageValue,
                bpHistory: history,
                hemoglobin: hbValue,
                diabetes: diabetes
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
