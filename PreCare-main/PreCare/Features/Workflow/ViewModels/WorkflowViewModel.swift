import Foundation
import Combine

@MainActor
final class WorkflowViewModel: ObservableObject {
    @Published var reportID = ""
    @Published var userID = SessionStore.shared.userID
    @Published var riskLevel = "DANGER"
    @Published var analysisText = "BP 160/100, Proteinuria present..."
    @Published var preferredDate = "2026-02-20"
    @Published var location = "Bangalore"
    @Published var locationCoordinates = "12.97,77.59"
    @Published var severity = "high"
    @Published var age = "24"
    @Published var bpHistory = "130/90,160/100"
    @Published var hemoglobin = "9.2"
    @Published var diabetes = false
    @Published var actionTaken = true

    @Published var isLoading = false
    @Published var output = ""
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func syncUserIDFromSession() {
        if userID.isEmpty {
            userID = SessionStore.shared.userID
        }
    }

    func runExtract() async {
        await runCall { [self] in
            try await self.apiClient.extractReport(reportID: self.reportID)
        }
    }

    func runAnalyzeRisk() async {
        await runCall { [self] in
            try await self.apiClient.analyzeRisk(reportID: self.reportID, text: self.analysisText)
        }
    }

    func runAgentPlan() async {
        await runCall { [self] in
            try await self.apiClient.planAgent(userID: self.userID, riskLevel: self.riskLevel, reportID: self.reportID)
        }
    }

    func runBookAppointment() async {
        await runCall { [self] in
            try await self.apiClient.bookAppointment(userID: self.userID, preferredDate: self.preferredDate)
        }
    }

    func runAutoBook() async {
        await runCall { [self] in
            try await self.apiClient.autoBookAppointment(userID: self.userID, location: self.location)
        }
    }

    func runEmergencyTrigger() async {
        await runCall { [self] in
            try await self.apiClient.triggerEmergency(userID: self.userID, location: self.locationCoordinates, severity: self.severity)
        }
    }

    func runDashboardFetch() async {
        await runCall { [self] in
            try await self.apiClient.userDashboard(userID: self.userID)
        }
    }

    func runTwinCreate() async {
        let ageValue = Int(age) ?? 24
        let hbValue = Double(hemoglobin) ?? 9.2
        let history = bpHistory
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        await runCall { [self] in
            try await self.apiClient.createTwin(
                userID: self.userID,
                age: ageValue,
                bpHistory: history,
                hemoglobin: hbValue,
                diabetes: self.diabetes
            )
        }
    }

    func runAgentConfirm() async {
        await runCall { [self] in
            try await self.apiClient.confirmAgent(reportID: self.reportID, actionTaken: self.actionTaken)
        }
    }

    private func runCall(_ action: @escaping () async throws -> String) async {
        guard !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "user_id is required"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            output = try await action()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
