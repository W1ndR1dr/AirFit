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

    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        return String(format: "#%06x", rgb)
    }
}
