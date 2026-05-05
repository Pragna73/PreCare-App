import SwiftUI

struct RoleBasedHomeView: View {
    @State private var role: UserRole = SessionStore.shared.userRole

    var body: some View {
        Group {
            switch role {
            case .patient:
                MainTabView()
            case .doctor:
                DoctorMainTabView()
            case .emergency:
                EmergencyMainTabView()
            case .staff:
                StaffMainTabView()
            }
        }
        .task {
            role = SessionStore.shared.userRole
        }
    }
}
