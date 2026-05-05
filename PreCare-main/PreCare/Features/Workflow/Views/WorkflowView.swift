import SwiftUI

struct WorkflowView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                headerCard

                navCard(
                    title: "Risk Analysis",
                    subtitle: "Extract report text and score risk",
                    icon: "waveform.path.ecg",
                    tint: Color(hex: "#0EA5E9"),
                    destination: RiskAnalysisView()
                )

                navCard(
                    title: "Agent Plan",
                    subtitle: "Generate and confirm care actions",
                    icon: "list.clipboard.fill",
                    tint: Color(hex: "#8B5CF6"),
                    destination: AgentPlanView()
                )

                navCard(
                    title: "Appointments",
                    subtitle: "Manual booking and nearest auto-book",
                    icon: "calendar.badge.plus",
                    tint: Color(hex: "#16A34A"),
                    destination: AppointmentOpsView()
                )

                navCard(
                    title: "Emergency",
                    subtitle: "Trigger urgent response workflow",
                    icon: "cross.case.fill",
                    tint: Color(hex: "#EF4444"),
                    destination: EmergencyOpsView()
                )

                navCard(
                    title: "Digital Twin",
                    subtitle: "Create patient twin health profile",
                    icon: "person.2.badge.gearshape.fill",
                    tint: Color(hex: "#F97316"),
                    destination: DigitalTwinView()
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Care Operations")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Backend Workflow")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Choose one module to continue.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func navCard<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        destination: Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            CardView {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(tint)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
