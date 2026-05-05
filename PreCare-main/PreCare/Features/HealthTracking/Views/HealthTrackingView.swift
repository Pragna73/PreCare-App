//
//  HealthTrackingView.swift
//  PreCare
//
 
//



import SwiftUI

struct HealthTrackingView: View {

    @StateObject private var vm = HealthTrackingViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PrimaryButton(title: vm.isLoading ? "Syncing..." : "Sync Metrics") {
                    Task {
                        await vm.saveCurrentMetricsAndRefresh()
                    }
                }
                .disabled(vm.isLoading)

                if let successMessage = vm.successMessage {
                    Text(successMessage)
                        .font(.footnote)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(vm.metrics) { metric in
                    CardView {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(metric.title)
                                    .font(.headline)

                                Text("\(metric.value) \(metric.unit)")
                                    .font(.title3)
                                    .fontWeight(.semibold)

                                Text(metric.status)
                                    .font(.caption)
                                    .foregroundColor(metric.status == "Low" ? .orange : .green)
                            }

                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Health Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.loadSummary()
        }
    }
}
