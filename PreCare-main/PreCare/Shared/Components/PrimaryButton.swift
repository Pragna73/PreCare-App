import SwiftUI

struct PrimaryButton: View {

    let title: String
    var color: Color = Color(hex: "#FF2D6F")
    let action: () -> Void

    init(
        title: String,
        color: Color = Color(hex: "#FF2D6F"),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .foregroundColor(.white)
            .frame(height: 54)
            .background(color)
            .cornerRadius(16)
        }
    }
}

