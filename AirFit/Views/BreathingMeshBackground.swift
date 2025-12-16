import SwiftUI

// MARK: - Tab Color Palettes for MeshGradient

/// Each tab has a 9-color palette for the 3x3 mesh grid
/// Colors are arranged: top-left, top-center, top-right, mid-left, center, mid-right, bottom-left, bottom-center, bottom-right
enum TabPalette {
    /// Dashboard (0) - Warm/Active: Coral, Peach, Lavender
    /// Dark mode: center is bright warm glow, edges fade to dark
    static func dashboard(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            Color(hex: "1A1614"), Color(hex: "2D2420"), Color(hex: "1A1618"),
            Color(hex: "2D2420"), Color(hex: "4A3830"), Color(hex: "2D2420"),
            Color(hex: "1A1618"), Color(hex: "2D2420"), Color(hex: "1A1614")
        ] : [
            Color(hex: "FFF0EC"), Color(hex: "FFE8E0"), Color(hex: "F5EBF7"),
            Color(hex: "FFE8E0"), Color(hex: "FFF8F0"), Color(hex: "FFE8E0"),
            Color(hex: "F5EBF7"), Color(hex: "FFE8E0"), Color(hex: "FFF0EC")
        ]
    }

    /// Nutrition (1) - Vitality: Sage Green, Peach, Warm
    static func nutrition(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            Color(hex: "141A16"), Color(hex: "1E2820"), Color(hex: "1A1614"),
            Color(hex: "1E2820"), Color(hex: "304838"), Color(hex: "1E2820"),
            Color(hex: "1A1614"), Color(hex: "1E2820"), Color(hex: "141A16")
        ] : [
            Color(hex: "E8F5ED"), Color(hex: "FFF3EC"), Color(hex: "FFF0EC"),
            Color(hex: "FFF3EC"), Color(hex: "FFF8F0"), Color(hex: "FFF3EC"),
            Color(hex: "FFF0EC"), Color(hex: "FFF3EC"), Color(hex: "E8F5ED")
        ]
    }

    /// Coach (2) - Communicative: Coral, Warm Peach, Tertiary
    static func coach(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            Color(hex: "1A1614"), Color(hex: "24201A"), Color(hex: "1A161A"),
            Color(hex: "24201A"), Color(hex: "483828"), Color(hex: "24201A"),
            Color(hex: "1A161A"), Color(hex: "24201A"), Color(hex: "1A1614")
        ] : [
            Color(hex: "FFF0EC"), Color(hex: "FFF5EB"), Color(hex: "F5EBF7"),
            Color(hex: "FFF5EB"), Color(hex: "FFF8F0"), Color(hex: "FFF5EB"),
            Color(hex: "F5EBF7"), Color(hex: "FFF5EB"), Color(hex: "FFF0EC")
        ]
    }

    /// Insights (3) - Contemplative: Lavender, Teal/Protein, Coral
    static func insights(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            Color(hex: "18161A"), Color(hex: "161E20"), Color(hex: "1A1614"),
            Color(hex: "161E20"), Color(hex: "2A3848"), Color(hex: "161E20"),
            Color(hex: "1A1614"), Color(hex: "161E20"), Color(hex: "18161A")
        ] : [
            Color(hex: "F5EBF7"), Color(hex: "E8F3F4"), Color(hex: "FFF0EC"),
            Color(hex: "E8F3F4"), Color(hex: "FFF8F0"), Color(hex: "E8F3F4"),
            Color(hex: "FFF0EC"), Color(hex: "E8F3F4"), Color(hex: "F5EBF7")
        ]
    }

    /// Profile (4) - Grounded: Taupe, Peach, Coral
    static func profile(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            Color(hex: "161614"), Color(hex: "201E1A"), Color(hex: "1A1614"),
            Color(hex: "201E1A"), Color(hex: "403830"), Color(hex: "201E1A"),
            Color(hex: "1A1614"), Color(hex: "201E1A"), Color(hex: "161614")
        ] : [
            Color(hex: "F0EBE6"), Color(hex: "FFF5EB"), Color(hex: "FFF0EC"),
            Color(hex: "FFF5EB"), Color(hex: "FFF8F0"), Color(hex: "FFF5EB"),
            Color(hex: "FFF0EC"), Color(hex: "FFF5EB"), Color(hex: "F0EBE6")
        ]
    }

    /// Get palette for tab index
    static func forTab(_ tab: Int, colorScheme: ColorScheme) -> [Color] {
        switch tab {
        case 0: return dashboard(for: colorScheme)
        case 1: return nutrition(for: colorScheme)
        case 2: return coach(for: colorScheme)
        case 3: return insights(for: colorScheme)
        case 4: return profile(for: colorScheme)
        default: return dashboard(for: colorScheme)
        }
    }
}

// MARK: - Breathing Mesh Background

struct BreathingMeshBackground: View {
    /// Scroll progress from 0.0 to 4.0 (5 tabs)
    let scrollProgress: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if reduceMotion {
            // Static gradient for reduce motion
            MeshGradient(
                width: 3,
                height: 3,
                points: staticPoints,
                colors: interpolatedColors
            )
        } else {
            TimelineView(.animation(minimumInterval: 1/60, paused: false)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate

                MeshGradient(
                    width: 3,
                    height: 3,
                    points: breathingPoints(time: time),
                    colors: interpolatedColors
                )
            }
        }
    }

    // MARK: - Static Points (for reduce motion)

    private var staticPoints: [SIMD2<Float>] {
        [
            SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
            SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
            SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
        ]
    }

    // MARK: - Breathing Animation

    /// 3x3 control points with slow, organic movement
    /// Creates a gentle "lava lamp" effect - noticeable but not distracting
    /// Edge corners stay fixed to prevent clipping
    private func breathingPoints(time: Double) -> [SIMD2<Float>] {
        // Multiple overlapping sine waves for organic motion
        // Slower periods for calm, ambient feel - but with more amplitude
        let wave1 = Float(sin(time * 0.15) * 0.12)   // ~7s period, ±12%
        let wave2 = Float(cos(time * 0.11) * 0.10)   // ~9s period, ±10%
        let wave3 = Float(sin(time * 0.19) * 0.08)   // ~5s period, ±8%
        let wave4 = Float(cos(time * 0.08) * 0.14)   // ~12s period, ±14%
        let wave5 = Float(sin(time * 0.13) * 0.06)   // ~8s period, ±6%

        return [
            // Top row - corners fixed, center breathes
            SIMD2(0.0, 0.0),
            SIMD2(0.5 + wave1, 0.0),
            SIMD2(1.0, 0.0),
            // Middle row - sides drift, center has most freedom (the "glow" moves)
            SIMD2(0.0, 0.5 + wave2),
            SIMD2(0.5 + wave3 + wave5, 0.5 + wave4),  // Center drifts most
            SIMD2(1.0, 0.5 - wave2),
            // Bottom row - corners fixed, center drifts opposite to top
            SIMD2(0.0, 1.0),
            SIMD2(0.5 - wave1, 1.0),
            SIMD2(1.0, 1.0)
        ]
    }

    // MARK: - Color Interpolation

    /// Interpolate between tab palettes based on scroll position
    private var interpolatedColors: [Color] {
        let clampedProgress = max(0, min(4, scrollProgress))
        let fromTab = Int(clampedProgress)
        let toTab = min(fromTab + 1, 4)
        let fraction = clampedProgress - CGFloat(fromTab)

        let fromPalette = TabPalette.forTab(fromTab, colorScheme: colorScheme)
        let toPalette = TabPalette.forTab(toTab, colorScheme: colorScheme)

        return zip(fromPalette, toPalette).map { from, to in
            interpolateColor(from, to, fraction: fraction)
        }
    }

    /// Linear interpolation between two colors
    private func interpolateColor(_ from: Color, _ to: Color, fraction: CGFloat) -> Color {
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]

        // Handle grayscale colors (2 components) vs RGB (4 components)
        let fromR = fromComponents.count >= 3 ? fromComponents[0] : fromComponents[0]
        let fromG = fromComponents.count >= 3 ? fromComponents[1] : fromComponents[0]
        let fromB = fromComponents.count >= 3 ? fromComponents[2] : fromComponents[0]
        let fromA = fromComponents.count >= 3 ? (fromComponents.count > 3 ? fromComponents[3] : 1.0) : (fromComponents.count > 1 ? fromComponents[1] : 1.0)

        let toR = toComponents.count >= 3 ? toComponents[0] : toComponents[0]
        let toG = toComponents.count >= 3 ? toComponents[1] : toComponents[0]
        let toB = toComponents.count >= 3 ? toComponents[2] : toComponents[0]
        let toA = toComponents.count >= 3 ? (toComponents.count > 3 ? toComponents[3] : 1.0) : (toComponents.count > 1 ? toComponents[1] : 1.0)

        let t = Double(fraction)
        return Color(
            red: fromR + (toR - fromR) * t,
            green: fromG + (toG - fromG) * t,
            blue: fromB + (toB - fromB) * t,
            opacity: fromA + (toA - fromA) * t
        )
    }
}

#Preview("Breathing Mesh - Dashboard") {
    BreathingMeshBackground(scrollProgress: 0.0)
        .ignoresSafeArea()
}

#Preview("Breathing Mesh - Mid-scroll") {
    BreathingMeshBackground(scrollProgress: 1.5)
        .ignoresSafeArea()
}

#Preview("Breathing Mesh - Dark Mode") {
    BreathingMeshBackground(scrollProgress: 2.0)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
}
