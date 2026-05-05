//
//  DashboardActionCard.swift
//  PreCare
//
 
//

import SwiftUI

struct DashboardActionCard: View {

    let title: String
    let subtitle: String
    let action: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Image(systemName: icon)
                .foregroundColor(Color(hex: "#FF2D6F"))
                .font(.title2)

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            Text(action)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "#FF2D6F"))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6)
        )
    }
}
