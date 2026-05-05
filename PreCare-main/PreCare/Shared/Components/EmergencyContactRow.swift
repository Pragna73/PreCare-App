//
//  EmergencyContactRow.swift
//  PreCare
//
 
//

import SwiftUI

struct EmergencyContactRow: View {

    let icon: String
    let title: String
    let number: String

    var body: some View {
        Button {
            callNumber(number)
        } label: {
            HStack(spacing: 12) {

                Image(systemName: icon)
                    .foregroundColor(.red)
                    .font(.title3)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)

                    Text(number)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
            }
        }
    }

    private func callNumber(_ number: String) {
        let cleaned = number
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "+", with: "")

        if let url = URL(string: "tel://\(cleaned)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
