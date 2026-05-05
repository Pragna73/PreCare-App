//
//  CriticalRiskView.swift
//  PreCare
//
 
//

import SwiftUI

struct CriticalRiskView: View {
    private func callEmergency() {
        let emergencyNumber = "911" // change if needed (112 / 108 for India)
        if let url = URL(string: "tel://\(emergencyNumber)") {
            UIApplication.shared.open(url)
        }
    }


    var body: some View {
        VStack(spacing: 28) {

            // MARK: - Alert Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            VStack(spacing: 8) {
                Text("Critical risk detected.")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("""
AI Analysis complete. Emergency protocols have been initiated automatically.
""")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            }

            // MARK: - Status Cards
            VStack(spacing: 16) {

                EmergencyActionRow(
                    title: "Ambulance dispatched",
                    subtitle: "ETA: 4 mins",
                    status: "CONFIRMED",
                    icon: "cross.case.fill"
                )

                EmergencyActionRow(
                    title: "Dr. Smith alerted",
                    subtitle: "Report #4921 sent",
                    status: "NOTIFIED",
                    icon: "stethoscope"
                )

                EmergencyActionRow(
                    title: "Family contacts",
                    subtitle: "Notifying husband...",
                    status: "IN PROGRESS",
                    icon: "person.2.fill"
                )
            }

            Spacer()

            // MARK: - Emergency Call
            PrimaryButton(title: "Call Emergency Services", color: .red) {
                callEmergency()
            }


            Button {
                // cancel alert
            } label: {
                Text("✕ I am safe, cancel alert")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }

            Spacer(minLength: 20)
        }
        .padding()
        .background(Color.black.opacity(0.95))
        .foregroundColor(.white)
        .navigationBarBackButtonHidden(true)
    }
}
