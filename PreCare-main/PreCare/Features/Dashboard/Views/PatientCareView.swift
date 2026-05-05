import SwiftUI

struct PatientCareView: View {
    @State private var isLoading = false
    @State private var message: String?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Care")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Appointments, nearby doctor support, and emergency help when needed.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Appointments")
                            .font(.headline)
                        Text("Book your routine prenatal checkup or let us find the nearest doctor automatically.")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        PrimaryButton(title: isLoading ? "Please wait..." : "Book Routine Appointment", color: Color(hex: "#16A34A")) {
                            runBookRoutine()
                        }

                        PrimaryButton(title: isLoading ? "Please wait..." : "Auto-Book Nearest Doctor", color: Color(hex: "#FF2D6F")) {
                            runAutoBook()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Emergency Help")
                            .font(.headline)
                        Text("If symptoms are severe, trigger immediate emergency support.")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        PrimaryButton(title: isLoading ? "Please wait..." : "Get Emergency Help", color: .red) {
                            runEmergency()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let message {
                    CardView {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let errorMessage {
                    CardView {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Care")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runBookRoutine() {
        guard let userID = validUserID() else { return }
        isLoading = true
        errorMessage = nil
        message = nil

        Task {
            do {
                let date = tomorrowDateString()
                let text = try await APIClient.shared.bookAppointment(userID: userID, preferredDate: date)
                message = text
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func runAutoBook() {
        guard let userID = validUserID() else { return }
        isLoading = true
        errorMessage = nil
        message = nil

        Task {
            do {
                let text = try await APIClient.shared.autoBookAppointment(userID: userID, location: "Bangalore")
                message = text
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func runEmergency() {
        guard let userID = validUserID() else { return }
        isLoading = true
        errorMessage = nil
        message = nil

        Task {
            do {
                let text = try await APIClient.shared.triggerEmergency(userID: userID, location: "12.97,77.59", severity: "high")
                message = text
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func validUserID() -> String? {
        let userID = SessionStore.shared.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userID.isEmpty else {
            errorMessage = "Please login again to continue."
            return nil
        }
        return userID
    }

    private func tomorrowDateString() -> String {
        let date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
