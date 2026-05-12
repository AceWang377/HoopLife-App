import SwiftUI

enum HLColor {
    static let background = Color(red: 0.055, green: 0.059, blue: 0.055)
    static let surface = Color(red: 0.965, green: 0.968, blue: 0.95)
    static let text = Color(red: 0.075, green: 0.078, blue: 0.071)
    static let secondaryText = Color(red: 0.42, green: 0.43, blue: 0.40)
    static let mutedText = Color(red: 0.58, green: 0.60, blue: 0.56)
    static let night = Color(red: 0.030, green: 0.034, blue: 0.032)
    static let courtGreen = Color(red: 0.02, green: 0.36, blue: 0.20)
    static let freshGreen = Color(red: 0.64, green: 0.92, blue: 0.38)
    static let electricBlue = Color(red: 0.13, green: 0.42, blue: 0.95)
    static let basketballOrange = Color(red: 0.98, green: 0.39, blue: 0.10)
    static let clay = Color(red: 0.66, green: 0.24, blue: 0.10)
    static let verified = Color(red: 0.12, green: 0.58, blue: 0.31)
    static let warning = Color(red: 0.82, green: 0.49, blue: 0.0)
    static let imported = Color(red: 0.50, green: 0.52, blue: 0.50)
    static let card = Color.white.opacity(0.94)
    static let softBlue = Color(red: 0.88, green: 0.925, blue: 1.0)
    static let softGreen = Color(red: 0.89, green: 0.97, blue: 0.86)
    static let softWarning = Color(red: 1.0, green: 0.94, blue: 0.80)
    static let stroke = Color(red: 0.83, green: 0.84, blue: 0.80)
    static let glass = Color.white.opacity(0.82)
}

extension View {
    func cardStyle(radius: CGFloat = 24) -> some View {
        self
            .background(HLColor.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.10), radius: 22, y: 10)
    }

    func pageBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [Color(red: 0.965, green: 0.968, blue: 0.95), Color(red: 0.90, green: 0.94, blue: 0.91)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
