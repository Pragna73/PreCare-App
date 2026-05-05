import SwiftUI

struct EmergencyOpsView: View {
    @StateObject private var vm = EmergencyOpsViewModel()
    @State private var selectedSeverity = "high"
    private let severities = ["low", "medium", "high"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emergency")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Trigger critical response with location and severity level.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(spacing: 12) {
                        TextField("User ID", text: $vm.userID)
                            .textFieldStyle(.roundedBorder)
                        TextField("Coordinates (lat,long)", text: $vm.locationCoordinates)
                            .textFieldStyle(.roundedBorder)
                        Picker("Severity", selection: $selectedSeverity) {
                            ForEach(severities, id: \.self) { severity in
                                Text(severity.capitalized).tag(severity)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                actionButton("Trigger Emergency", color: Color(hex: "#EF4444")) {
                    vm.severity = selectedSeverity
                    await vm.triggerEmergency()
                }

                outputCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Emergency")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.syncUserID()
            selectedSeverity = vm.severity
        }
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
