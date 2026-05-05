import SwiftUI

struct DoctorMainTabView: View {
    var body: some View {
        TabView {
            DoctorDashboardView()
                .tabItem { Label("Dashboard", systemImage: "stethoscope") }

            AppointmentOpsView()
                .tabItem { Label("Appointments", systemImage: "calendar.badge.clock") }

            WorkflowView()
                .tabItem { Label("Actions", systemImage: "list.clipboard") }

            AskMayaView()
                .tabItem { Label("Maya", systemImage: "message.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(Color(hex: "#0EA5E9"))
    }
}

private struct DoctorDashboardView: View {
    @State private var reports: [ReportSummaryItem] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Doctor Console")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Review risk cases, monitor escalations, and manage patient actions.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                summaryCard("Critical Cases", "\(reports.filter { $0.riskLevel.uppercased() == "DANGER" }.count)", color: .red)
                summaryCard("Warning Cases", "\(reports.filter { ["WARNING", "MODERATE"].contains($0.riskLevel.uppercased()) }.count)", color: .orange)
                summaryCard("Total Reports", "\(reports.count)", color: .blue)

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Patient Reports")
                            .font(.headline)
                        if isLoading {
                            ProgressView("Loading reports...")
                        } else if reports.isEmpty {
                            Text("No reports available right now.")
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

    private func summaryCard(_ title: String, _ value: String, color: Color) -> some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline).foregroundColor(.secondary)
                    Text(value).font(.title3).fontWeight(.bold).foregroundColor(color)
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
