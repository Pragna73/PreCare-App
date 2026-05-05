
import SwiftUI

struct StatCard: View {

    let title: String
    let action: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Image(systemName: icon)
                .foregroundColor(Color(hex: "#FF2D6F"))
                .font(.title2)

            Text(title)
                .font(.headline)

            Spacer()

            Text(action)
                .font(.subheadline)
                .foregroundColor(Color(hex: "#FF2D6F"))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6)
        )
    }
}

