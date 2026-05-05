import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            UploadReportView()
                .tabItem {
                    Label("Reports", systemImage: "doc.badge.plus")
                }

            AIResultTabView()
                .tabItem {
                    Label("Health", systemImage: "heart.text.square.fill")
                }

            PatientCareView()
                .tabItem {
                    Label("Care", systemImage: "calendar")
                }

            AskMayaView()
                .tabItem {
                    Label("Ask Maya", systemImage: "message.fill")
                }
        }
        .tint(Color(hex: "#FF2D6F"))
    }
}
