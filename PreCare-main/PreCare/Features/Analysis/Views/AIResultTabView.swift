import SwiftUI

struct AIResultTabView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var report: ReportItem?
    @State private var reportList: [ReportSummaryItem] = []

    var body: some View {
        Group {
            if let report {
                AnalysisResultView(severity: severity(from: report.riskLevel), report: report)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        CardView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("No AI Result Yet")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Upload a pregnancy report to see extracted data, risk classification, and recommended actions.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if isLoading {
                            ProgressView("Loading latest report...")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !reportList.isEmpty {
                            CardView {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Your Reports")
                                        .font(.headline)
                                    ForEach(reportList) { item in
                                        Button {
                                            Task { await loadReport(id: item.id) }
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.filename)
                                                        .font(.subheadline)
                                                        .foregroundColor(.primary)
                                                    Text("Risk: \(friendlyRisk(item.riskLevel))")
                                                        .font(.caption)
                                                        .foregroundColor(riskColor(item.riskLevel))
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        PrimaryButton(title: "Refresh Result") {
                            Task { await loadLatestReport() }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("AI Result")
                .navigationBarTitleDisplayMode(.inline)
                .task { await loadLatestReport() }
            }
        }
    }

    private func loadLatestReport() async {
        await loadReportHistory()

        let latestReportID = SessionStore.shared.latestReportID
        guard !latestReportID.isEmpty else {
            report = nil
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            report = try await APIClient.shared.report(id: latestReportID)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func loadReportHistory() async {
        let userID = SessionStore.shared.userID
        guard !userID.isEmpty else { return }
        do {
            reportList = try await APIClient.shared.userReports(userID: userID)
        } catch {
            // Keep existing UI calm; this section is optional.
        }
    }

    private func loadReport(id: String) async {
        isLoading = true
        errorMessage = nil
        do {
            report = try await APIClient.shared.report(id: id)
            SessionStore.shared.saveLatestReportID(id)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func severity(from risk: String?) -> HealthSeverity {
        switch (risk ?? "").uppercased() {
        case "GOOD", "FINE":
            return .safe
        case "WARNING", "MODERATE":
            return .warning
        case "DANGER":
            return .critical
        default:
            return .safe
        }
    }

    private func friendlyRisk(_ risk: String) -> String {
        switch risk.uppercased() {
        case "FINE":
            return "GOOD"
        case "MODERATE":
            return "WARNING"
        default:
            return risk.uppercased()
        }
    }

    private func riskColor(_ risk: String) -> Color {
        switch friendlyRisk(risk) {
        case "GOOD":
            return .green
        case "WARNING":
            return .orange
        default:
            return .red
        }
    }
}
