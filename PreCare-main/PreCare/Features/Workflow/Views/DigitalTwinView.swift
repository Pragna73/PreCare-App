import SwiftUI

struct DigitalTwinView: View {
    @StateObject private var vm = DigitalTwinViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Digital Twin")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Build a data twin profile to personalize health planning.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(spacing: 12) {
                        TextField("User ID", text: $vm.userID)
                            .textFieldStyle(.roundedBorder)

                        HStack(spacing: 10) {
                            TextField("Age", text: $vm.age)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                            TextField("Hemoglobin", text: $vm.hemoglobin)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                        }

                        TextField("BP History (130/90,160/100)", text: $vm.bpHistory)
                            .textFieldStyle(.roundedBorder)

                        Toggle("Diabetes", isOn: $vm.diabetes)
                    }
                }

                actionButton("Create Digital Twin", color: Color(hex: "#F97316")) { await vm.createTwin() }

                outputCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Digital Twin")
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
