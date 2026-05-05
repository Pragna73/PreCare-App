import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var phone = ""
    @Published var emergencyContact = ""

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func loginUser(onSuccess: @escaping () -> Void) {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let session = try await apiClient.login(
                    LoginPayload(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password
                    )
                )

                SessionStore.shared.saveAccessToken(session.accessToken, userID: session.userID, role: session.role)

                if let user = try? await apiClient.me() {
                    SessionStore.shared.saveUser(name: user.fullName, email: user.email, role: user.role)
                }

                isLoading = false
                onSuccess()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func registerUser(onSuccess: @escaping () -> Void) {
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            errorMessage = "Name, email, and password are required."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let userID = try await apiClient.register(
                    RegisterPayload(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        name: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password,
                        role: "PATIENT",
                        phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                        emergencyContact: emergencyContact.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                )

                let session = try await apiClient.login(
                    LoginPayload(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password
                    )
                )

                SessionStore.shared.saveAccessToken(session.accessToken, userID: session.userID ?? userID, role: session.role)

                if let user = try? await apiClient.me() {
                    SessionStore.shared.saveUser(name: user.fullName, email: user.email, role: user.role)
                }

                isLoading = false
                onSuccess()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func logout() {
        SessionStore.shared.clearSession()
    }
}
