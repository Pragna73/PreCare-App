import Foundation
import Combine

@MainActor
final class HealthTrackingViewModel: ObservableObject {

    @Published var metrics: [HealthMetric] = [
        HealthMetric(title: "Hemoglobin", value: "11.3", unit: "g/dL", status: "Low"),
        HealthMetric(title: "Blood Pressure", value: "128/85", unit: "mmHg", status: "Normal"),
        HealthMetric(title: "Blood Glucose", value: "95", unit: "mg/dL", status: "Normal"),
        HealthMetric(title: "Weight", value: "77", unit: "kg", status: "Normal")
    ]

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func loadSummary() async {
        isLoading = true
        errorMessage = nil

        do {
            let summary = try await apiClient.healthTrackingSummary()
            apply(summary)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func saveCurrentMetricsAndRefresh() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            let payload = HealthMetricsPayload(
                hemoglobin: 11.3,
                systolicBP: 128,
                diastolicBP: 85,
                bloodGlucose: 95,
                weightKG: 77
            )

            try await apiClient.submitHealthMetrics(payload)
            successMessage = "Metrics synced successfully"

            let summary = try await apiClient.healthTrackingSummary()
            apply(summary)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ summary: HealthTrackingSummary) {
        let hemoglobin = summary.hemoglobin ?? 11.3
        let systolic = summary.systolicBP ?? 128
        let diastolic = summary.diastolicBP ?? 85
        let glucose = summary.bloodGlucose ?? 95
        let weight = summary.weightKG ?? 77

        metrics = [
            HealthMetric(
                title: "Hemoglobin",
                value: String(format: "%.1f", hemoglobin),
                unit: "g/dL",
                status: summary.hemoglobinStatus ?? (hemoglobin < 12 ? "Low" : "Normal")
            ),
            HealthMetric(
                title: "Blood Pressure",
                value: "\(systolic)/\(diastolic)",
                unit: "mmHg",
                status: summary.bloodPressureStatus ?? ((systolic <= 140 && diastolic <= 90) ? "Normal" : "High")
            ),
            HealthMetric(
                title: "Blood Glucose",
                value: "\(glucose)",
                unit: "mg/dL",
                status: summary.bloodGlucoseStatus ?? (glucose <= 140 ? "Normal" : "High")
            ),
            HealthMetric(
                title: "Weight",
                value: String(format: "%.1f", weight),
                unit: "kg",
                status: summary.weightStatus ?? "Normal"
            )
        ]
    }
}
