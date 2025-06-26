import SwiftUI

/// Pre-curated gradient tokens that define AirFit's visual language
/// Each gradient has light and dark mode variants for seamless appearance transitions
enum GradientToken: String, CaseIterable {
    // Original tokens
    case peachRose      // Morning energy
    case mintAqua       // Fresh start
    case lilacBlush     // Evening calm
    case skyLavender    // Night serenity
    case sageMelon      // Balanced vitality
    case butterLemon    // Sunny disposition
    case icePeriwinkle  // Cool focus
    case rosewoodPlum   // Gentle strength
    case coralMist      // Warm embrace
    case sproutMint     // Growth mindset
    case dawnPeach      // New beginnings
    case duskBerry      // Reflection time

    // Sunrise journey tokens
    case nightSky       // Pre-dawn darkness (deep blue/purple)
    case earlyTwilight  // First hint of light (dark purple/blue)
    case morningTwilight // Twilight colors (purple/pink)
    case firstLight     // Dawn breaking (deep pink/orange)
    case sunrise        // Actual sunrise (orange/pink)
    case morningGlow    // Golden hour (pink/yellow)
    case brightMorning  // Late morning (yellow/light blue)

    /// Returns the gradient colors for the current color scheme
    func colors(for colorScheme: ColorScheme) -> [Color] {
        switch (self, colorScheme) {
        // Light mode gradients
        case (.peachRose, .light):
            return [Color(hex: "#FDE4D2"), Color(hex: "#F9C7D6")]
        case (.mintAqua, .light):
            return [Color(hex: "#D3F6F1"), Color(hex: "#B7E8F4")]
        case (.lilacBlush, .light):
            return [Color(hex: "#E9E7FD"), Color(hex: "#DCD3F9")]
        case (.skyLavender, .light):
            return [Color(hex: "#DFF2FD"), Color(hex: "#D8DEFF")]
        case (.sageMelon, .light):
            return [Color(hex: "#E8F9E3"), Color(hex: "#FFF0CB")]
        case (.butterLemon, .light):
            return [Color(hex: "#FFF8DB"), Color(hex: "#FFE4C2")]
        case (.icePeriwinkle, .light):
            return [Color(hex: "#E6FAFF"), Color(hex: "#E9E6FF")]
        case (.rosewoodPlum, .light):
            return [Color(hex: "#FCD5E8"), Color(hex: "#E5D1F8")]
        case (.coralMist, .light):
            return [Color(hex: "#FEE3D6"), Color(hex: "#EBD6F5")]
        case (.sproutMint, .light):
            return [Color(hex: "#E5F8D4"), Color(hex: "#CBF1E2")]
        case (.dawnPeach, .light):
            return [Color(hex: "#FDE6D4"), Color(hex: "#F7E1FD")]
        case (.duskBerry, .light):
            return [Color(hex: "#F3D8F2"), Color(hex: "#D8E1FF")]

        // Sunrise journey gradients - light mode
        case (.nightSky, .light):
            return [Color(hex: "#1A1B3A"), Color(hex: "#2D2B5F")]  // Deep blue/purple - white text
        case (.earlyTwilight, .light):
            return [Color(hex: "#2D2B5F"), Color(hex: "#4A4B8C")]  // Dark purple/blue - white text
        case (.morningTwilight, .light):
            return [Color(hex: "#4A4B8C"), Color(hex: "#7B6BA3")]  // Purple/pink - white text
        case (.firstLight, .light):
            return [Color(hex: "#9B7BA8"), Color(hex: "#E8A598")]  // Deep pink/orange - transition text
        case (.sunrise, .light):
            return [Color(hex: "#FFAB91"), Color(hex: "#FFD4E5")]  // Orange/pink - dark text
        case (.morningGlow, .light):
            return [Color(hex: "#FFD4E5"), Color(hex: "#FFF4B6")]  // Pink/yellow - dark text
        case (.brightMorning, .light):
            return [Color(hex: "#FFF4B6"), Color(hex: "#E3F2FD")]  // Yellow/light blue - dark text

        // Dark mode gradients - deeper, moodier variants
        case (.peachRose, .dark):
            return [Color(hex: "#4A3642"), Color(hex: "#5A3A4A")]
        case (.mintAqua, .dark):
            return [Color(hex: "#13313D"), Color(hex: "#14444F")]
        case (.lilacBlush, .dark):
            return [Color(hex: "#24203B"), Color(hex: "#2E2946")]
        case (.skyLavender, .dark):
            return [Color(hex: "#15283A"), Color(hex: "#1C2541")]
        case (.sageMelon, .dark):
            return [Color(hex: "#29372A"), Color(hex: "#3A3724")]
        case (.butterLemon, .dark):
            return [Color(hex: "#3B3623"), Color(hex: "#46341F")]
        case (.icePeriwinkle, .dark):
            return [Color(hex: "#1F3540"), Color(hex: "#252B4A")]
        case (.rosewoodPlum, .dark):
            return [Color(hex: "#3A2436"), Color(hex: "#301E41")]
        case (.coralMist, .dark):
            return [Color(hex: "#3A2723"), Color(hex: "#33263B")]
        case (.sproutMint, .dark):
            return [Color(hex: "#283827"), Color(hex: "#1F4033")]
        case (.dawnPeach, .dark):
            return [Color(hex: "#3D2720"), Color(hex: "#2F233A")]
        case (.duskBerry, .dark):
            return [Color(hex: "#3A2638"), Color(hex: "#212849")]

        // Sunrise journey gradients - dark mode
        case (.nightSky, .dark):
            return [Color(hex: "#0A0B1A"), Color(hex: "#15162F")]
        case (.earlyTwilight, .dark):
            return [Color(hex: "#15162F"), Color(hex: "#252546")]
        case (.morningTwilight, .dark):
            return [Color(hex: "#252546"), Color(hex: "#3D3551")]
        case (.firstLight, .dark):
            return [Color(hex: "#4D3D54"), Color(hex: "#744A4C")]
        case (.sunrise, .dark):
            return [Color(hex: "#7F5548"), Color(hex: "#7F6A72")]
        case (.morningGlow, .dark):
            return [Color(hex: "#7F6A72"), Color(hex: "#7F7A5B")]
        case (.brightMorning, .dark):
            return [Color(hex: "#7F7A5B"), Color(hex: "#71797E")]

        @unknown default:
            // Fallback to peach rose if unknown color scheme
            return [Color(hex: "#FDE4D2"), Color(hex: "#F9C7D6")]
        }
    }

    /// Creates a linear gradient for this token
    func linearGradient(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colors(for: colorScheme),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Creates a radial gradient for special effects
    func radialGradient(for colorScheme: ColorScheme) -> RadialGradient {
        RadialGradient(
            colors: colors(for: colorScheme),
            center: .center,
            startRadius: 0,
            endRadius: 200
        )
    }

    /// Human-readable name for debugging
    var displayName: String {
        switch self {
        case .peachRose: return "Peach Rose"
        case .mintAqua: return "Mint Aqua"
        case .lilacBlush: return "Lilac Blush"
        case .skyLavender: return "Sky Lavender"
        case .sageMelon: return "Sage Melon"
        case .butterLemon: return "Butter Lemon"
        case .icePeriwinkle: return "Ice Periwinkle"
        case .rosewoodPlum: return "Rosewood Plum"
        case .coralMist: return "Coral Mist"
        case .sproutMint: return "Sprout Mint"
        case .dawnPeach: return "Dawn Peach"
        case .duskBerry: return "Dusk Berry"
        case .nightSky: return "Night Sky"
        case .earlyTwilight: return "Early Twilight"
        case .morningTwilight: return "Morning Twilight"
        case .firstLight: return "First Light"
        case .sunrise: return "Sunrise"
        case .morningGlow: return "Morning Glow"
        case .brightMorning: return "Bright Morning"
        }
    }

    /// Computes optimal text color based on gradient using color theory and perceptual luminance
    func optimalTextColor(for colorScheme: ColorScheme) -> Color {
        let colors = self.colors(for: colorScheme)
        guard !colors.isEmpty else { return .primary }

        // Get the average color of the gradient for text color calculation
        let averageColor = averageColor(from: colors)

        // Calculate perceptual luminance using WCAG formula
        let luminance = perceptualLuminance(of: averageColor)

        // For very dark backgrounds, calculate a warm-tinted light color
        if luminance < 0.15 {
            // Extract hue from average color and create a warm white
            let uiColor = UIColor(averageColor)
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0

            uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

            // Shift hue slightly towards warm (yellow/orange range: 0.08-0.16)
            let warmHue = hue * 0.3 + 0.08
            return Color(hue: warmHue, saturation: 0.1, brightness: 0.98)
        }

        // For mid-tone backgrounds, use high contrast color based on hue
        if luminance < 0.5 {
            // Get the dominant hue and create a deep, saturated version
            let uiColor = UIColor(averageColor)
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0

            uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

            // Shift hue slightly for better contrast
            let contrastHue = (hue + 0.15).truncatingRemainder(dividingBy: 1.0)
            return Color(hue: contrastHue, saturation: 0.7, brightness: 0.25)
        }

        // For bright backgrounds, calculate complementary dark color
        let uiColor = UIColor(averageColor)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Use analogous color (30-60 degrees shift) for harmony
        let analogousHue = (hue + 0.12).truncatingRemainder(dividingBy: 1.0)

        // Create a deep, rich color
        return Color(
            hue: analogousHue,
            saturation: min(saturation * 1.5, 0.8),
            brightness: 0.2 + (1.0 - luminance) * 0.15
        )
    }

    /// Calculate perceptual luminance using WCAG formula
    private func perceptualLuminance(of color: Color) -> Double {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Apply gamma correction
        let r = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let g = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let b = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)

        // Calculate relative luminance
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Calculate average color from gradient colors
    private func averageColor(from colors: [Color]) -> Color {
        guard !colors.isEmpty else { return .gray }

        var totalRed: CGFloat = 0
        var totalGreen: CGFloat = 0
        var totalBlue: CGFloat = 0

        for color in colors {
            let uiColor = UIColor(color)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            totalRed += red
            totalGreen += green
            totalBlue += blue
        }

        let count = CGFloat(colors.count)
        return Color(
            red: totalRed / count,
            green: totalGreen / count,
            blue: totalBlue / count
        )
    }

    /// Get secondary text color (for subtitles, descriptions)
    func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        let primary = optimalTextColor(for: colorScheme)
        // Add opacity to primary color for hierarchy
        return primary.opacity(0.75)
    }

    /// Get accent color for interactive elements
    func accentColor(for colorScheme: ColorScheme) -> Color {
        let colors = self.colors(for: colorScheme)
        let averageColor = averageColor(from: colors)
        let luminance = perceptualLuminance(of: averageColor)

        // Use color wheel theory to find complementary accent
        let uiColor = UIColor(averageColor)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // For dark backgrounds, use a bright complementary color
        if luminance < 0.3 {
            // Shift hue by 150-210° for interesting contrast
            let accentHue = (hue + 0.42 + (saturation * 0.16)).truncatingRemainder(dividingBy: 1.0)
            return Color(
                hue: accentHue,
                saturation: 0.6 + saturation * 0.2,
                brightness: 0.7 + luminance
            )
        }

        // For mid-tone backgrounds, use split-complementary
        if luminance < 0.6 {
            // Split complementary: 150° shift
            let splitHue = (hue + 0.417).truncatingRemainder(dividingBy: 1.0)
            return Color(
                hue: splitHue,
                saturation: min(saturation * 1.3, 0.85),
                brightness: 0.5 + (0.6 - luminance) * 0.5
            )
        }

        // For bright backgrounds, use triadic harmony
        let triadicHue = (hue + 0.333).truncatingRemainder(dividingBy: 1.0)
        return Color(
            hue: triadicHue,
            saturation: min(saturation * 1.4, 0.9),
            brightness: 0.4 - luminance * 0.2
        )
    }
}
