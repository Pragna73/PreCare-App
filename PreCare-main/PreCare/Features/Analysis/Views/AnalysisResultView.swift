import SwiftUI

struct AnalysisResultView: View {
    let severity: HealthSeverity
    let report: ReportItem?

    init(severity: HealthSeverity = .safe, report: ReportItem? = nil) {
        self.severity = severity
        self.report = report
    }

    @State private var isSubmittingDecision = false
    @State private var decisionError: String?
    @State private var decisionMessage: String?
    @State private var showDecision = false
    @State private var locationName = "Bangalore, IN"
    @State private var showLocationEditor = false
    @State private var locationInput = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerCard
                nearbyHelpCard

                extractedDataCard
                structuredDataCard
                analysisCard
                recommendationCard
                autoActionsCard

                if report?.requiresConfirmation == true {
                    HStack(spacing: 12) {
                        Button {
                            submitConfirmation(true)
                        } label: {
                            Text(isSubmittingDecision ? "Please wait..." : "Confirm")
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .foregroundColor(.white)
                                .background(Color(hex: "#16A34A"))
                                .cornerRadius(14)
                        }
                        .disabled(isSubmittingDecision)

                        Button {
                            submitConfirmation(false)
                        } label: {
                            Text(isSubmittingDecision ? "Please wait..." : "Deny")
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .foregroundColor(.white)
                                .background(Color(hex: "#EF4444"))
                                .cornerRadius(14)
                        }
                        .disabled(isSubmittingDecision)
                    }
                }

                if let decisionMessage {
                    Text(decisionMessage)
                        .font(.footnote)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let decisionError {
                    Text(decisionError)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(title: "View Agentic AI Decision") { showDecision = true }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(isPresented: $showDecision) {
            AIHealthDecisionView(severity: severity, report: report)
        }
        .sheet(isPresented: $showLocationEditor) {
            NavigationStack {
                VStack(spacing: 14) {
                    TextField("City, Country", text: $locationInput)
                        .textFieldStyle(.roundedBorder)

                    PrimaryButton(title: "Use This Location") {
                        let trimmed = locationInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            locationName = trimmed
                        }
                        showLocationEditor = false
                    }
                }
                .padding()
                .navigationTitle("Change Location")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .navigationTitle("Analysis Result")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Report Processed")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("📍 Using your location: \(locationName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Change location") {
                    locationInput = locationName
                    showLocationEditor = true
                }
                .font(.caption)
                Text("Review extracted data, risk classification, recommendations, and auto-generated actions.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var nearbyHelpCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Help Near You")
                    .font(.headline)
                Text("Based on your current location")
                    .font(.caption)
                    .foregroundColor(.secondary)

                availabilityRow(icon: "🚑", title: "Ambulance", value: "Available (ETA: 7 mins)", state: .available)
                availabilityRow(icon: "🏥", title: "Nearest Hospital", value: "Cloudnine Hospital (2.1 km away)", state: .available)
                availabilityRow(icon: "👩‍⚕️", title: "Doctor On-Call", value: "Dr. Meena (Available now)", state: .available)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func availabilityRow(icon: String, title: String, value: String, state: AvailabilityState) -> some View {
        HStack(spacing: 10) {
            Text(icon)
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                Text(value)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var extractedDataCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Extracted Data")
                    .font(.headline)
                if let text = report?.extractedText, !text.isEmpty {
                    Text(text)
                        .font(.system(.footnote, design: .monospaced))
                        .lineLimit(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                } else {
                    Text("No extracted text available.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var structuredDataCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Structured Data")
                    .font(.headline)
                if let structured = report?.structuredData, !structured.isEmpty {
                    ForEach(structured.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(pretty(key))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(value)
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                    }
                } else {
                    Text("No structured fields available.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var analysisCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Analysis")
                    .font(.headline)
                Text("Risk: \(riskDisplay)")
                    .font(.subheadline)
                    .foregroundColor(riskColor)
                if let score = report?.riskScore {
                    Text("Score: \(String(format: "%.2f", score))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if let reason = report?.riskReason, !reason.isEmpty {
                     Text(reason)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var recommendationCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommendation")
                    .font(.headline)
                Text(report?.recommendation ?? "No recommendation available.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                if let signals = report?.keySignals, !signals.isEmpty {
                    Text("Signals: \(signals.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var autoActionsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Auto Actions")
                    .font(.headline)
                if let plans = report?.agentPlans, !plans.isEmpty {
                    ForEach(Array(plans.enumerated()), id: \.offset) { _, plan in
                        Text("• \(plan.action) (\(plan.status))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No auto actions returned.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var riskDisplay: String {
        if let level = report?.riskLevel, !level.isEmpty {
            switch level.uppercased() {
            case "FINE": return "GOOD"
            case "MODERATE": return "WARNING"
            default: return level.uppercased()
            }
        }
        switch severity {
        case .safe: return "GOOD"
        case .warning: return "WARNING"
        case .critical: return "DANGER"
        }
    }

    private var riskColor: Color {
        switch riskDisplay {
        case "GOOD": return .green
        case "WARNING", "MODERATE": return .orange
        default: return .red
        }
    }

    private func submitConfirmation(_ confirm: Bool) {
        guard let reportID = report?.id else { return }
        isSubmittingDecision = true
        decisionError = nil
        decisionMessage = nil

        Task {
            do {
                try await APIClient.shared.confirmReport(id: reportID, confirm: confirm)
                decisionMessage = confirm ? "Action confirmed successfully." : "Action denied successfully."
                isSubmittingDecision = false
            } catch {
                decisionError = error.localizedDescription
                isSubmittingDecision = false
            }
        }
    }

    private func pretty(_ key: String) -> String {
        key
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

private enum AvailabilityState {
    case available
    case limited
    case unavailable

    var color: Color {
        switch self {
        case .available:
            return .green
        case .limited:
            return .orange
        case .unavailable:
            return .gray
        }
    }
}
