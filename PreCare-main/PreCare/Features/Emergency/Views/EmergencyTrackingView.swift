//
//  EmergencyTrackingView.swift
//  PreCare
//
 
//

import SwiftUI
import MapKit

struct EmergencyTrackingView: View {

    @StateObject private var vm = EmergencyViewModel()

    // MARK: - Map State
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 17.3850,   // Example: Hyderabad
            longitude: 78.4867
        ),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    // Mock ambulance location
    private let ambulanceCoordinate = CLLocationCoordinate2D(
        latitude: 17.3870,
        longitude: 78.4890
    )

    private func callFamily() {
        let number = "9876543210"
        if let url = URL(string: "tel://\(number)") {
            UIApplication.shared.open(url)
        }
    }

    var body: some View {
        VStack(spacing: 24) {

            // MARK: - ETA
            VStack(spacing: 6) {
                Text("\(vm.etaMinutes) min")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.green)

                Text("Ambulance arriving soon")
                    .foregroundColor(.gray)
            }

            // MARK: - LIVE MAP
            Map(coordinateRegion: $region, annotationItems: [
                MapPinItem(
                    coordinate: ambulanceCoordinate,
                    title: "Ambulance"
                )
            ]) { item in
                MapMarker(coordinate: item.coordinate, tint: .green)
            }
            .frame(height: 200)
            .cornerRadius(16)
            .overlay(
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    Text(vm.distance)
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(8),
                alignment: .bottomLeading
            )

            // MARK: - Live Status
            VStack(spacing: 16) {

                EmergencyStatusRow(
                    icon: "cross.case.fill",
                    title: "Paramedics",
                    subtitle: "En Route • \(vm.etaMinutes) min",
                    confirmed: true
                )

                EmergencyStatusRow(
                    icon: "stethoscope",
                    title: "Dr. Alisha",
                    subtitle: "Viewing Report",
                    confirmed: true
                )

                EmergencyStatusRow(
                    icon: "person.2.fill",
                    title: "Husband (Mark)",
                    subtitle: "Notified",
                    confirmed: true
                )
            }

            Spacer()

            // MARK: - Call Buttons
            PrimaryButton(title: "Call Mark", color: .green) {
                callFamily()
            }

            Button {
                if let url = URL(string: "tel://911") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("SOS  Call 911 / Emergency")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }

            Spacer(minLength: 20)
        }
        .padding()
        .navigationTitle("Emergency Status")
        .navigationBarTitleDisplayMode(.inline)
    }
}
