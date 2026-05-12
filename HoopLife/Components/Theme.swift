import SwiftUI

enum HLColor {
    static let background = Color(red: 0.965, green: 0.961, blue: 0.933)
    static let surface = Color(red: 0.988, green: 0.984, blue: 0.957)
    static let text = Color(red: 0.075, green: 0.078, blue: 0.071)
    static let secondaryText = Color(red: 0.38, green: 0.39, blue: 0.37)
    static let mutedText = Color(red: 0.56, green: 0.57, blue: 0.54)
    static let night = Color(red: 0.052, green: 0.066, blue: 0.056)
    static let courtGreen = Color(red: 0.035, green: 0.392, blue: 0.239)
    static let freshGreen = Color(red: 0.17, green: 0.68, blue: 0.42)
    static let electricBlue = Color(red: 0.055, green: 0.326, blue: 0.89)
    static let basketballOrange = Color(red: 0.96, green: 0.43, blue: 0.12)
    static let clay = Color(red: 0.77, green: 0.31, blue: 0.12)
    static let verified = Color(red: 0.12, green: 0.58, blue: 0.31)
    static let warning = Color(red: 0.82, green: 0.49, blue: 0.0)
    static let imported = Color(red: 0.50, green: 0.52, blue: 0.50)
    static let card = Color.white.opacity(0.96)
    static let softBlue = Color(red: 0.89, green: 0.925, blue: 1.0)
    static let softGreen = Color(red: 0.88, green: 0.955, blue: 0.905)
    static let softWarning = Color(red: 1.0, green: 0.94, blue: 0.80)
    static let stroke = Color(red: 0.83, green: 0.84, blue: 0.80)
    static let glass = Color.white.opacity(0.82)
}

extension View {
    func cardStyle(radius: CGFloat = 24) -> some View {
        self
            .background(HLColor.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 18, y: 8)
    }

    func pageBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [HLColor.background, Color(red: 0.935, green: 0.946, blue: 0.91)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
