import SwiftUI
import UIKit

struct AIHealthDecisionView: View {

    let severity: HealthSeverity
    let report: ReportItem?

    init(severity: HealthSeverity, report: ReportItem? = nil) {
        self.severity = severity
        self.report = report
    }

    @State private var isRunningAction = false
    @State private var actionStatus: String?
    @State private var actionError: String?
    @State private var locationName = "Bangalore, IN"
    @State private var showLocationEditor = false
    @State private var locationInput = ""

    // MARK: - Navigation State
    @State private var goToDoctor = false
    @State private var goToEmergency = false
    @State private var goToCritical = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                decisionCard
                nearbyHelpCard
                meaningCard
                actionButtons

                if let actionStatus {
                    CardView {
                        Text(actionStatus)
                            .font(.footnote)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if let actionError {
                    CardView {
                        Text(actionError)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Health Decision")
        .navigationBarTitleDisplayMode(.inline)
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

        // MARK: - Navigation Destinations
        .navigationDestination(isPresented: $goToDoctor) {
            BookDoctorView()
        }
        .navigationDestination(isPresented: $goToEmergency) {
            EmergencyTrackingView()
        }
        .navigationDestination(isPresented: $goToCritical) {
            CriticalRiskView()
        }
    }

    // MARK: - Decision Card
    private var decisionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleText)
                .font(.headline)
                .foregroundColor(titleColor)
            Text("📍 Using your location: \(locationName)")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Change location") {
                locationInput = locationName
                showLocationEditor = true
            }
            .font(.caption)

            Text(descriptionText)
                .font(.subheadline)
                .foregroundColor(.gray)

            if let report {
                if let reason = report.riskReason {
                    Text("Reason: \(reason)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                if let recommendation = report.recommendation {
                    Text("Recommendation: \(recommendation)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                if let status = report.confirmationStatus {
                    Text("Confirmation: \(status)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                if let plan = report.agentPlans.first {
                    Text("Plan: \(plan.action) (\(plan.status))")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    if let doctor = plan.doctor, let hospital = plan.hospital {
                        Text("\(doctor) • \(hospital)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        switch effectiveSeverity {

        case .safe:
            CardView {
                Text("3 clinics near you are available for routine checkups.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: isRunningAction ? "Please wait..." : "📅 Book Nearest Clinic", color: Color(hex: "#16A34A")) {
                runGoodFlow()
            }
            .disabled(isRunningAction)

            Button("Skip for now") {
                actionStatus = "No problem. You can schedule a routine checkup anytime."
            }
            .font(.footnote)
            .foregroundColor(.secondary)

        case .warning:
            CardView {
                Text("Dr. Meena is available today at Cloudnine Hospital (2.1 km).")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(title: isRunningAction ? "Please wait..." : "✅ Confirm Appointment", color: .orange) {
                runWarningFlow()
            }
            .disabled(isRunningAction)

            PrimaryButton(title: "❌ Choose Another Doctor", color: Color(hex: "#FF2D6F")) {
                goToDoctor = true
            }

        case .critical:
            PrimaryButton(title: isRunningAction ? "Please wait..." : "🚨 Call Ambulance (ETA 7 mins)", color: .red) {
                runDangerFlow()
            }
            .disabled(isRunningAction)

            PrimaryButton(title: "📞 Call Emergency Contact", color: .orange) {
                callEmergencyContact()
            }

            if !isAmbulanceAvailable {
                CardView {
                    Text("No ambulance nearby. Calling nearest hospital emergency line.")
                        .font(.footnote)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Button("View Emergency Status") {
                goToCritical = true
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Computed Values
    private var titleText: String {
        switch effectiveSeverity {
        case .safe: return "GOOD: You Are Safe"
        case .warning: return "WARNING: Needs Attention"
        case .critical: return "DANGER: Critical Alert"
        }
    }

    private var descriptionText: String {
        if let recommendation = report?.recommendation, !recommendation.isEmpty {
            return recommendation
        }
        switch effectiveSeverity {
        case .safe:
            return "Everything looks normal. Do you want me to book a doctor for a routine checkup?"
        case .warning:
            return "Your vitals indicate a potential issue. Please consider consulting a doctor."
        case .critical:
            return "Your vitals indicate a serious risk. PreCare AI has automatically initiated doctor booking."
        }
    }

    private var titleColor: Color {
        switch effectiveSeverity {
        case .safe: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    private var cardBackground: Color {
        titleColor.opacity(0.12)
    }

    private var effectiveSeverity: HealthSeverity {
        guard let risk = report?.riskLevel?.uppercased() else { return severity }
        switch risk {
        case "FINE", "GOOD":
            return .safe
        case "MODERATE", "WARNING", "URGENT":
            return .warning
        case "DANGER", "CRITICAL":
            return .critical
        default:
            return severity
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

                helpRow("🚑", "Ambulance", isAmbulanceAvailable ? "Available (ETA: 7 mins)" : "Not available nearby", state: isAmbulanceAvailable ? .available : .unavailable)
                helpRow("🏥", "Nearest Hospital", "Cloudnine Hospital (2.1 km away)", state: .available)
                helpRow("👩‍⚕️", "Doctor On-Call", "Dr. Meena (Available now)", state: .limited)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var meaningCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 6) {
                Text("What this means")
                    .font(.headline)
                Text("Based on your location, help is available nearby. We’ve already found the fastest option for you.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func helpRow(_ icon: String, _ title: String, _ subtitle: String, state: HelpAvailability) -> some View {
        HStack(spacing: 10) {
            Text(icon)
            Circle().fill(state.color).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private func runGoodFlow() {
        guard let userID = validUserID() else { return }
        runAction {
            let date = Self.tomorrowDateString()
            _ = try await APIClient.shared.bookAppointment(userID: userID, preferredDate: date)
            await MainActor.run {
                actionStatus = "Nearest clinic booked for \(date)."
                goToDoctor = true
            }
        }
    }

    private func runWarningFlow() {
        guard let userID = validUserID() else { return }
        runAction {
            _ = try await APIClient.shared.autoBookAppointment(userID: userID, location: "Bangalore")
            if let reportID = report?.id, report?.requiresConfirmation == true {
                try await APIClient.shared.confirmReport(id: reportID, confirm: true)
            }
            await MainActor.run {
                actionStatus = "Appointment confirmed with nearest available doctor."
            }
        }
    }

    private func runDangerFlow() {
        guard let userID = validUserID() else { return }
        runAction {
            _ = try await APIClient.shared.triggerEmergency(userID: userID, location: "12.97,77.59", severity: "high")
            _ = try await APIClient.shared.autoBookAppointment(userID: userID, location: "Bangalore")
            await MainActor.run {
                actionStatus = "Emergency triggered. Ambulance dispatched, doctor alerted, and family notified."
                goToCritical = true
            }
        }
    }

    private func runAction(_ action: @escaping () async throws -> Void) {
        isRunningAction = true
        actionError = nil
        actionStatus = nil
        Task {
            do {
                try await action()
                isRunningAction = false
            } catch {
                actionError = error.localizedDescription
                isRunningAction = false
            }
        }
    }

    private func validUserID() -> String? {
        let userID = SessionStore.shared.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userID.isEmpty else {
            actionError = "Missing user_id. Please login again."
            return nil
        }
        return userID
    }

    private var isAmbulanceAvailable: Bool {
        true
    }

    private func callEmergencyContact() {
        if let url = URL(string: "tel://112") {
            UIApplication.shared.open(url)
        } else {
            actionError = "Unable to place emergency call on this device."
        }
    }

    private static func tomorrowDateString() -> String {
        let date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private enum HelpAvailability {
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
