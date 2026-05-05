import SwiftUI

struct ProfileView: View {

    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {

                // MARK: - Profile Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 90))
                        .foregroundColor(.white)

                    Text(vm.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(vm.email)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FF5A8A"),
                            Color(hex: "#FF2D6F")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.08), radius: 8)

                // MARK: - Personal Information Card
                CardView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Information")
                            .font(.headline)

                        InfoRow(title: "Full Name", value: vm.name)
                        Divider()
                        InfoRow(title: "Email", value: vm.email)
                    }
                }

                // MARK: - Notification Preferences Card
                CardView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notification Preferences")
                            .font(.headline)

                        Toggle("Email Notifications", isOn: $vm.emailNotification)
                        Toggle("Push Notifications", isOn: $vm.pushNotification)
                        Toggle("Report Reminders", isOn: $vm.reportReminder)
                    }
                }

                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 20)
                
                // MARK: - Emergency Contacts
                CardView {
                    NavigationLink {
                        EmergencyContactsView(vm: vm)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Emergency Contacts")
                                    .font(.headline)

                                Text("Family members to notify in emergencies")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer(minLength: 20)
                // MARK: - Logout (Dev)
                Button {
                    Task {
                        await vm.logout()
                        router.path = NavigationPath()
                    }
                } label: {
                    Text("Logout")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.4))
                        )
                }
            }
            .padding()
        }
        .task {
            await vm.loadProfileData()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
