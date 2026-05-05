import SwiftUI

struct StaffMainTabView: View {
    var body: some View {
        TabView {
            StaffDashboardView()
                .tabItem { Label("Dashboard", systemImage: "building.2.fill") }

            WorkflowView()
                .tabItem { Label("Workflow", systemImage: "square.grid.2x2") }

            AppointmentOpsView()
                .tabItem { Label("Schedules", systemImage: "calendar") }

            AskMayaView()
                .tabItem { Label("Maya", systemImage: "message.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(Color(hex: "#8B5CF6"))
    }
}

private struct StaffDashboardView: View {
    @State private var reports: [ReportSummaryItem] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Healthcare Staff Portal")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Operational control for report pipeline, booking queues, and escalation logs.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                metric("Reports Processed", "\(reports.count)")
                metric("Pending WARNING Confirmations", "\(reports.filter { ["WARNING", "MODERATE"].contains($0.riskLevel.uppercased()) }.count)")
                metric("Danger Escalations", "\(reports.filter { $0.riskLevel.uppercased() == "DANGER" }.count)")

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Latest Reports Queue")
                            .font(.headline)
                        if isLoading {
                            ProgressView("Loading queue...")
                        } else if reports.isEmpty {
                            Text("No reports in queue.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(reports.prefix(5)) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.filename)
                                            .font(.footnote)
                                        Text("Risk: \(friendlyRisk(item.riskLevel))")
                                            .font(.caption)
                                            .foregroundColor(riskColor(item.riskLevel))
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await loadReports()
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Spacer()
            }
        }
    }

    private func loadReports() async {
        isLoading = true
        reports = (try? await APIClient.shared.allReports()) ?? []
        isLoading = false
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
