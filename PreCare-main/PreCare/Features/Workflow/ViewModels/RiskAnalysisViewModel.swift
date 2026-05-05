import Foundation
import Combine

@MainActor
final class RiskAnalysisViewModel: ObservableObject {
    @Published var reportID = ""
    @Published var analysisText = "BP 160/100, Proteinuria present..."
    @Published var isLoading = false
    @Published var output = ""
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func extractReport() async {
        guard !reportID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Report ID is required"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            output = try await apiClient.extractReport(reportID: reportID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func analyzeRisk() async {
        guard !reportID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Report ID is required"
            return
        }
        guard !analysisText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Analysis text is required"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            output = try await apiClient.analyzeRisk(reportID: reportID, text: analysisText)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
