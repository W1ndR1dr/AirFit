import SwiftUI

/// Pre-curated gradient tokens that define AirFit's visual language
/// Each gradient has light and dark mode variants for seamless appearance transitions
enum GradientToken: String, CaseIterable {
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
            
        // Dark mode gradients - deeper, moodier variants
        case (.peachRose, .dark):
            return [Color(hex: "#362128"), Color(hex: "#412932")]
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
        }
    }
}