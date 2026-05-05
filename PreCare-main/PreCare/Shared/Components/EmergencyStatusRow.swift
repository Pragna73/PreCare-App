//
//  EmergencyStatusRow.swift
//  PreCare
//
 
//

import SwiftUI

struct EmergencyStatusRow: View {

    let icon: String
    let title: String
    let subtitle: String
    let confirmed: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)

            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if confirmed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.12))
        )
    }
}
