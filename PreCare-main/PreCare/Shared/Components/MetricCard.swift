import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let status: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(value).font(.title2)
            Text(status).foregroundColor(color)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).stroke())
    }
}
