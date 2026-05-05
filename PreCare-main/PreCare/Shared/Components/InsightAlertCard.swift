//
//  InsightAlertCard.swift
//  PreCare
//
 
//

import SwiftUI

struct InsightAlertCard: View {

    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.12))
        )
    }
}
