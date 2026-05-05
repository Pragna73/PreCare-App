import SwiftUI

struct AgentPlanView: View {
    @StateObject private var vm = AgentPlanViewModel()
    @State private var selectedRisk = "DANGER"
    private let riskLevels = ["FINE", "MODERATE", "DANGER"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Agent Plan")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Create care workflow actions and confirm completion.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(spacing: 12) {
                        TextField("User ID", text: $vm.userID)
                            .textFieldStyle(.roundedBorder)
                        TextField("Report ID", text: $vm.reportID)
                            .textFieldStyle(.roundedBorder)
                        Picker("Risk Level", selection: $selectedRisk) {
                            ForEach(riskLevels, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                        Toggle("Action Taken", isOn: $vm.actionTaken)
                    }
                }

                actionButton("Generate Agent Plan", color: Color(hex: "#8B5CF6")) {
                    vm.riskLevel = selectedRisk
                    await vm.generatePlan()
                }
                actionButton("Confirm Agent Action", color: Color(hex: "#FF2D6F")) { await vm.confirmAction() }

                outputCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Agent Plan")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.syncUserID()
            selectedRisk = vm.riskLevel
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
