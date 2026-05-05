import SwiftUI

struct AppointmentOpsView: View {
    @StateObject private var vm = AppointmentOpsViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appointments")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Schedule appointments manually or auto-book nearby options.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(spacing: 12) {
                        TextField("User ID", text: $vm.userID)
                            .textFieldStyle(.roundedBorder)
                        TextField("Preferred Date (YYYY-MM-DD)", text: $vm.preferredDate)
                            .textFieldStyle(.roundedBorder)
                        TextField("Location", text: $vm.location)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                actionButton("Book Appointment", color: Color(hex: "#16A34A")) { await vm.bookAppointment() }
                actionButton("Auto Book Appointment", color: Color(hex: "#FF2D6F")) { await vm.autoBookAppointment() }

                outputCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .task { vm.syncUserID() }
    }

    private var outputCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("API Result").font(.headline)
                if let error = vm.errorMessage {
                    Text(error).font(.footnote).foregroundColor(.red)
                } else if vm.output.isEmpty {
                    Text("No output yet").font(.footnote).foregroundColor(.secondary)
                } else {
                    Text(vm.output)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func actionButton(_ title: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Text(vm.isLoading ? "Please wait..." : title)
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundColor(.white)
                .background(color)
                .cornerRadius(12)
        }
        .disabled(vm.isLoading)
    }
}
