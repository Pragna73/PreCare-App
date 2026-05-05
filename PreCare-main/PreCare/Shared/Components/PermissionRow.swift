//
//  PermissionRow.swift
//  PreCare
//
 
//

import SwiftUI

struct PermissionRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.pink)
                .font(.title2)

            VStack(alignment: .leading) {
                Text(title).fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }
}
