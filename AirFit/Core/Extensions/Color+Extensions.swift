import SwiftUI

extension Color {
    init(hex: String) {
        var hexFormatted = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hexFormatted.count == 6 {
            hexFormatted.append("FF")
        }
        var int: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&int)
        let a, r, g, b: UInt64
        (a, r, g, b) = (int >> 24 & 0xff, int >> 16 & 0xff, int >> 8 & 0xff, int & 0xff)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
