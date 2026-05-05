//
//  InfoRow.swift
//  PreCare
//
 
//

import SwiftUI

struct InfoRow: View {

    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}
