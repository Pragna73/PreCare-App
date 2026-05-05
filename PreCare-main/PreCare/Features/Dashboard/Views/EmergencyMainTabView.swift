import SwiftUI

struct EmergencyMainTabView: View {
    var body: some View {
        TabView {
            EmergencyResponderDashboardView()
                .tabItem { Label("Dashboard", systemImage: "cross.case.fill") }

            EmergencyOpsView()
                .tabItem { Label("Trigger", systemImage: "exclamationmark.triangle.fill") }

            EmergencyTrackingView()
                .tabItem { Label("Tracking", systemImage: "location.fill") }

            AskMayaView()
                .tabItem { Label("Maya", systemImage: "message.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(.red)
    }
}

private struct EmergencyResponderDashboardView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emergency Control")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Manage ambulance dispatch, doctor alerts, and family notifications.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                emergencyCard("Active DANGER Alerts", "2", color: .red)
                emergencyCard("Ambulances En Route", "4", color: .orange)
                emergencyCard("Avg ETA", "7 mins", color: .green)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func emergencyCard(_ title: String, _ value: String, color: Color) -> some View {
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
}
