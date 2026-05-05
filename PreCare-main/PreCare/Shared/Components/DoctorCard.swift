//
//  DoctorCard.swift
//  PreCare
//
 
//

import SwiftUI

struct DoctorCard: View {

    let doctor: Doctor
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: "stethoscope")
                .font(.title2)
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name)
                    .font(.headline)

                Text(doctor.specialization)
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)

                    Text(String(format: "%.1f", doctor.rating))
                        .font(.caption)

                    Text("• \(doctor.availability)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
