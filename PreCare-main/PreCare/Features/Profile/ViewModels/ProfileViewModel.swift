import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var name: String
    @Published var email: String

    @Published var emailNotification = true
    @Published var pushNotification = false
    @Published var reportReminder = true

    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
        self.name = SessionStore.shared.cachedName
        self.email = SessionStore.shared.cachedEmail
    }

    func loadProfileData() async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await apiClient.me()
            name = user.fullName
            email = user.email
            SessionStore.shared.saveUser(name: user.fullName, email: user.email, role: user.role)

            emergencyContacts = try await apiClient.emergencyContacts()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func refreshContacts() async {
        do {
            emergencyContacts = try await apiClient.emergencyContacts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addEmergencyContact(name: String, relation: String, phone: String) async -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !relation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "All emergency contact fields are required."
            return false
        }

        do {
            let newContact = try await apiClient.addEmergencyContact(
                EmergencyContactPayload(
                    label: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    phoneNumber: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                    relationship: relation.trimmingCharacters(in: .whitespacesAndNewlines),
                    isPrimary: false
                )
            )

            emergencyContacts.append(newContact)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() async {
        do {
            try await apiClient.logout()
        } catch {
            // Clear local session even if server logout fails.
        }

        SessionStore.shared.clearSession()
    }
}
