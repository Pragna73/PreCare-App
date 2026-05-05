import SwiftUI

struct RiskAnalysisView: View {
    @StateObject private var vm = RiskAnalysisViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Risk Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Extract text from uploaded report and run AI risk classification.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardView {
                    VStack(spacing: 12) {
                        TextField("Report ID (ex: rep_456)", text: $vm.reportID)
                            .textFieldStyle(.roundedBorder)
                        TextField("Clinical text for risk analysis", text: $vm.analysisText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(4...7)
                    }
                }

                HStack(spacing: 10) {
                    actionButton("Extract", color: Color(hex: "#0EA5E9")) { await vm.extractReport() }
                    actionButton("Analyze", color: Color(hex: "#FF2D6F")) { await vm.analyzeRisk() }
                }

                outputCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Risk Analysis")
        .navigationBarTitleDisplayMode(.inline)
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
