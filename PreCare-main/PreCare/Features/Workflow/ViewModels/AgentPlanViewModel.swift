import Foundation
import Combine

@MainActor
final class AgentPlanViewModel: ObservableObject {
    @Published var userID = SessionStore.shared.userID
    @Published var reportID = ""
    @Published var riskLevel = "DANGER"
    @Published var actionTaken = true
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

    func generatePlan() async {
        guard !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !reportID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "User ID and Report ID are required"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            output = try await apiClient.planAgent(userID: userID, riskLevel: riskLevel, reportID: reportID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func confirmAction() async {
        guard !reportID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Report ID is required"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            output = try await apiClient.confirmAgent(reportID: reportID, actionTaken: actionTaken)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
