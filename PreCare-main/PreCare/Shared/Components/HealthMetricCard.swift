//
//  HealthMetricCard.swift
//  PreCare
//
 
//


import SwiftUI

struct HealthMetricCard: View {

    let title: String
    let value: String
    let normalRange: String
    let status: String
    let statusColor: Color
    let trend: String
    let trendUp: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text("Normal: \(normalRange)")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 4) {
                Image(systemName: trendUp ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(trendUp ? .green : .red)

                Text(trend)
                    .font(.caption)
                    .foregroundColor(trendUp ? .green : .red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6)
        )
    }
}
