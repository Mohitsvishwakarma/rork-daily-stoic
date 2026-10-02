import SwiftUI

/// Design tokens for the marble-and-bronze visual system.
enum Theme {
    static let canvas = Color(hex: 0xF3EFE7)      // warm ivory background
    static let surface = Color(hex: 0xFFFFFF)     // card surfaces
    static let bronze = Color(hex: 0x9C6B3F)      // primary accent
    static let bronzeDeep = Color(hex: 0x7E5230)  // pressed accent
    static let bronzeTint = Color(hex: 0xF1E6D8)  // chips / soft fills
    static let charcoal = Color(hex: 0x2B2A28)    // primary text
    static let warmGray = Color(hex: 0x6E6862)    // secondary text
    static let muted = Color(hex: 0xA79E92)       // tertiary / locked
    static let sand = Color(hex: 0xE9E2D5)        // tracks / inactive
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Card surface used across screens: white, soft corner radius, gentle shadow.
struct CardSurface: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface.opacity(0.92))
                    .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 8)
            )
    }
}

extension View {
    func cardSurface(cornerRadius: CGFloat = 24) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius))
    }
}

/// Press feedback for primary buttons: scale + slight dim.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
