import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var dashboardMessage: String = ""
    @Published var latestReport: ReportItem?
    @Published var isBackendHealthy = false
    @Published var latestRiskLevel = "No report"
    @Published var nextAppointment = "No appointment"
    @Published var emergencyStatus = "No active emergency"

    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    var latestSeverity: HealthSeverity {
        guard let risk = latestReport?.riskLevel?.uppercased() else {
            return .safe
        }

        switch risk {
        case "DANGER":
            return .critical
        case "MODERATE":
            return .warning
        case "FINE":
            return .safe
        default:
            return .safe
        }
    }

    func loadDashboard() async {
        errorMessage = nil

        do {
            try await apiClient.health()
            isBackendHealthy = true
        } catch {
            isBackendHealthy = false
            errorMessage = error.localizedDescription
            return
        }

        do {
            let userID = SessionStore.shared.userID
            if !userID.isEmpty {
                dashboardMessage = try await apiClient.userDashboard(userID: userID)
            } else {
                dashboardMessage = try await apiClient.dashboard()
            }

            let snapshot = try await apiClient.dashboardSnapshot(userID: userID)
            latestRiskLevel = snapshot.latestRiskLevel ?? "No report"
            nextAppointment = snapshot.nextAppointmentLabel ?? "No appointment"
            emergencyStatus = snapshot.emergencyStatus ?? "No active emergency"

            if let reportID = snapshot.lastUploadedReportID, !reportID.isEmpty {
                SessionStore.shared.saveLatestReportID(reportID)
                latestReport = try? await apiClient.report(id: reportID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadAndFetchReport(fileURL: URL, patientName: String?) async -> Bool {
        isLoading = true
        errorMessage = nil

        let userID = SessionStore.shared.userID
        guard !userID.isEmpty else {
            isLoading = false
            errorMessage = "Missing user_id. Please sign in again."
            return false
        }

        do {
            let uploaded = try await apiClient.uploadReport(fileURL: fileURL, userID: userID, patientName: patientName)
            let fetched = try await apiClient.report(id: uploaded.id)
            latestReport = fetched
            SessionStore.shared.saveLatestReportID(fetched.id)
            latestRiskLevel = fetched.riskLevel ?? latestRiskLevel
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }

    func confirmLatestReport() async {
        guard let latestReport else { return }
        guard latestReport.requiresConfirmation else {
            dashboardMessage = "Confirmation is not required for this report."
            return
        }

        do {
            try await apiClient.confirmReport(id: latestReport.id, confirm: true)
            dashboardMessage = "Report confirmed"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
