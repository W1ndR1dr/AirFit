import SwiftUI

// MARK: - Tab Color Palettes for MeshGradient

/// Each tab has a 16-color palette for the 4x4 mesh grid
/// SOFT PASTEL AURORA: Gentle, dreamy colors that blend organically
enum TabPalette {
    /// Dashboard (0) - Warm Sunset: Coral + Teal + Gold distributed across mesh
    static func dashboard(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            // Colors distributed throughout - not just center. Multiple hue zones.
            // Row 0: dark base with hints
            Color(hex: "161412"), Color(hex: "2A2420"), Color(hex: "1E2830"), Color(hex: "161816"),
            // Row 1: coral zone left, teal zone right
            Color(hex: "3A2A22"), Color(hex: "A87060"), Color(hex: "4A8088"), Color(hex: "283840"),
            // Row 2: warm transition
            Color(hex: "382820"), Color(hex: "986050"), Color(hex: "3A7078"), Color(hex: "243038"),
            // Row 3: grounded with color hints
            Color(hex: "181614"), Color(hex: "302820"), Color(hex: "1C2428"), Color(hex: "161412")
        ] : [
            Color(hex: "FBF8F6"), Color(hex: "F4ECEA"), Color(hex: "E8F2F4"), Color(hex: "F9F7F5"),
            Color(hex: "F6F0EA"), Color(hex: "F2D4C8"), Color(hex: "C8E0E4"), Color(hex: "EAF4F6"),
            Color(hex: "F4ECE4"), Color(hex: "E8CCC0"), Color(hex: "C0D8DC"), Color(hex: "ECF6F8"),
            Color(hex: "F9F7F5"), Color(hex: "F2EAE6"), Color(hex: "EAF4F4"), Color(hex: "FBF8F6")
        ]
    }

    /// Nutrition (1) - Fresh Garden: Emerald + Rose + Gold distributed
    static func nutrition(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            // Emerald in corners, rose accents, gold highlights
            Color(hex: "141A18"), Color(hex: "1C2820"), Color(hex: "281C22"), Color(hex: "181816"),
            // Row 1: green left, pink right
            Color(hex: "1E3828"), Color(hex: "509870"), Color(hex: "986878"), Color(hex: "2A2028"),
            // Row 2: reversed for variety
            Color(hex: "283020"), Color(hex: "408860"), Color(hex: "885868"), Color(hex: "241C24"),
            // Row 3: grounded
            Color(hex: "161816"), Color(hex: "1E2A22"), Color(hex: "221A1E"), Color(hex: "141816")
        ] : [
            Color(hex: "F4FAF6"), Color(hex: "E8F4EC"), Color(hex: "F6ECF0"), Color(hex: "F6F8F6"),
            Color(hex: "E4F2E8"), Color(hex: "C0E0D0"), Color(hex: "E8D0D8"), Color(hex: "F4EEF2"),
            Color(hex: "E8F4EA"), Color(hex: "CCE8D8"), Color(hex: "E0C8D0"), Color(hex: "F2ECF0"),
            Color(hex: "F6F8F6"), Color(hex: "EAF6EE"), Color(hex: "F4EEF2"), Color(hex: "F4FAF6")
        ]
    }

    /// Coach (2) - Warm Glow: Amber + Violet + Cream distributed
    static func coach(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            // Amber warmth top-left, violet cool bottom-right
            Color(hex: "1A1612"), Color(hex: "2C2418"), Color(hex: "1C1824"), Color(hex: "18161A"),
            // Row 1: amber dominant
            Color(hex: "382C1C"), Color(hex: "A87848"), Color(hex: "6858A0"), Color(hex: "1E1C30"),
            // Row 2: transitioning
            Color(hex: "342818"), Color(hex: "986840"), Color(hex: "584890"), Color(hex: "1A1A2C"),
            // Row 3: violet hints
            Color(hex: "181616"), Color(hex: "2A221A"), Color(hex: "1C182A"), Color(hex: "181618")
        ] : [
            Color(hex: "FAF8F4"), Color(hex: "F4ECE0"), Color(hex: "F0EEF6"), Color(hex: "F8F6F6"),
            Color(hex: "F4EEE4"), Color(hex: "F0D8C0"), Color(hex: "DCD4EC"), Color(hex: "F0EEF8"),
            Color(hex: "F2EAE0"), Color(hex: "E8D0B8"), Color(hex: "D4CCE4"), Color(hex: "EEECF6"),
            Color(hex: "F8F6F4"), Color(hex: "F2ECE6"), Color(hex: "F0EEF8"), Color(hex: "FAF8F6")
        ]
    }

    /// Insights (3) - Deep Twilight: Electric Blue + Cyan + Purple distributed
    static func insights(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            // Electric blue top, purple bottom, cyan accents
            Color(hex: "10141C"), Color(hex: "182838"), Color(hex: "1C1428"), Color(hex: "121418"),
            // Row 1: cyan-blue zone
            Color(hex: "182C44"), Color(hex: "4888B8"), Color(hex: "7068B0"), Color(hex: "1A1838"),
            // Row 2: deeper purple zone
            Color(hex: "142440"), Color(hex: "3878A8"), Color(hex: "6058A0"), Color(hex: "181634"),
            // Row 3: grounded with hints
            Color(hex: "121418"), Color(hex: "1A2432"), Color(hex: "181428"), Color(hex: "10141A")
        ] : [
            Color(hex: "F4F6FA"), Color(hex: "E4EEF6"), Color(hex: "F0ECF8"), Color(hex: "F6F6F8"),
            Color(hex: "E4ECF8"), Color(hex: "C0D8F0"), Color(hex: "D8D0EC"), Color(hex: "ECEAF6"),
            Color(hex: "E8F0FA"), Color(hex: "B8D0E8"), Color(hex: "D0C8E4"), Color(hex: "EAE8F4"),
            Color(hex: "F6F6F8"), Color(hex: "E8F0F6"), Color(hex: "EEEAF8"), Color(hex: "F4F6FA")
        ]
    }

    /// Profile (4) - Refined Neutral: Bronze + Sage + Rose distributed
    static func profile(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? [
            // Warm bronze top-left, cool sage bottom-right
            Color(hex: "181614"), Color(hex: "242018"), Color(hex: "182018"), Color(hex: "161816"),
            // Row 1: bronze zone
            Color(hex: "2C2820"), Color(hex: "988868"), Color(hex: "608870"), Color(hex: "1E2420"),
            // Row 2: sage zone
            Color(hex: "28241C"), Color(hex: "887858"), Color(hex: "507860"), Color(hex: "1C221E"),
            // Row 3: neutral base with hints
            Color(hex: "161816"), Color(hex: "222018"), Color(hex: "1A201C"), Color(hex: "181816")
        ] : [
            Color(hex: "F8F8F4"), Color(hex: "F2EEE8"), Color(hex: "EEF4F0"), Color(hex: "F6F6F4"),
            Color(hex: "F0ECE4"), Color(hex: "E4DCD0"), Color(hex: "D8E8DC"), Color(hex: "F0F4F0"),
            Color(hex: "EEEAE2"), Color(hex: "DCD4C8"), Color(hex: "D0E0D4"), Color(hex: "EEF2EE"),
            Color(hex: "F6F6F4"), Color(hex: "F0ECE8"), Color(hex: "EEF2EE"), Color(hex: "F8F8F6")
        ]
    }

    /// Get 16-color palette for tab index (4x4 grid)
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

// MARK: - Aurora Mesh Background

/// A living, breathing aurora-like mesh gradient
/// Features:
/// - 4x4 control point grid for organic "folds"
/// - Multi-frequency organic motion with visible breathing
/// - Scroll-reactive directional wave effect
/// - Smooth color interpolation between tabs
struct BreathingMeshBackground: View {
    /// Scroll progress from 0.0 to 4.0 (5 tabs)
    let scrollProgress: CGFloat

    /// Enable debug mode to diagnose animation issues
    var debugMode: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    /// Reference time when view first appeared - used for smooth relative animation
    @State private var startTime: Date?

    var body: some View {
        if reduceMotion {
            // Static gradient for reduce motion
            MeshGradient(
                width: 4,
                height: 4,
                points: staticPoints,
                colors: interpolatedColors
            )
        } else {
            TimelineView(.animation(minimumInterval: 1/60, paused: false)) { timeline in
                // Use relative time from first frame - avoids Float precision issues
                // and ensures smooth continuous animation
                let elapsed = startTime.map { timeline.date.timeIntervalSince($0) } ?? 0
                let points = debugMode ? debugPoints(time: elapsed) : auroraPoints(time: elapsed)

                ZStack {
                    MeshGradient(
                        width: 4,
                        height: 4,
                        points: points,
                        colors: debugMode ? debugColors : interpolatedColors
                    )

                    // Debug overlay showing animation is running
                    if debugMode {
                        debugOverlay(time: elapsed, points: points)
                    }
                }
            }
            .onAppear {
                if startTime == nil {
                    startTime = Date()
                }
            }
        }
    }

    // MARK: - Debug Mode

    /// EXTREMELY dramatic debug animation to verify system is working
    private func debugPoints(time: Double) -> [SIMD2<Float>] {
        // time is now relative (starts at 0), so Float conversion is safe
        let t = Float(time)

        // Interior point 5 moves in a HUGE circle
        let angle5 = t * 0.5  // One rotation every ~12 seconds
        let center5X: Float = 0.35
        let center5Y: Float = 0.35
        let radius5: Float = 0.20  // HUGE movement
        let point5X = center5X + cos(angle5) * radius5
        let point5Y = center5Y + sin(angle5) * radius5

        // Interior point 6 moves opposite
        let angle6 = t * 0.5 + .pi
        let center6X: Float = 0.65
        let center6Y: Float = 0.35
        let point6X = center6X + cos(angle6) * radius5
        let point6Y = center6Y + sin(angle6) * radius5

        // Interior point 9
        let angle9 = t * 0.5 + .pi / 2
        let center9X: Float = 0.35
        let center9Y: Float = 0.65
        let point9X = center9X + cos(angle9) * radius5
        let point9Y = center9Y + sin(angle9) * radius5

        // Interior point 10
        let angle10 = t * 0.5 + 3 * .pi / 2
        let center10X: Float = 0.65
        let center10Y: Float = 0.65
        let point10X = center10X + cos(angle10) * radius5
        let point10Y = center10Y + sin(angle10) * radius5

        return [
            // Row 0 - top edge
            SIMD2(0, 0), SIMD2(0.33, 0), SIMD2(0.66, 0), SIMD2(1, 0),
            // Row 1
            SIMD2(0, 0.33), SIMD2(point5X, point5Y), SIMD2(point6X, point6Y), SIMD2(1, 0.33),
            // Row 2
            SIMD2(0, 0.66), SIMD2(point9X, point9Y), SIMD2(point10X, point10Y), SIMD2(1, 0.66),
            // Row 3 - bottom edge
            SIMD2(0, 1), SIMD2(0.33, 1), SIMD2(0.66, 1), SIMD2(1, 1)
        ]
    }

    /// High contrast debug colors to see mesh movement clearly
    private var debugColors: [Color] {
        [
            // Row 0 - dark corners, bright edges
            .black, .blue, .cyan, .black,
            // Row 1 - the interior points are BRIGHT
            .purple, .red, .orange, .green,
            // Row 2
            .indigo, .yellow, .pink, .mint,
            // Row 3
            .black, .teal, .blue, .black
        ]
    }

    /// Debug overlay showing time and point positions
    private func debugOverlay(time: Double, points: [SIMD2<Float>]) -> some View {
        VStack {
            // Time indicator - proves TimelineView is updating
            Text("t: \(String(format: "%.2f", time.truncatingRemainder(dividingBy: 100)))")
                .font(.caption.monospaced())
                .padding(4)
                .background(.black.opacity(0.7))
                .foregroundStyle(.green)
                .cornerRadius(4)

            // Point 5 position
            Text("P5: (\(String(format: "%.3f", points[5].x)), \(String(format: "%.3f", points[5].y)))")
                .font(.caption2.monospaced())
                .padding(4)
                .background(.black.opacity(0.7))
                .foregroundStyle(.yellow)
                .cornerRadius(4)

            Spacer()

            // reduceMotion status
            Text("reduceMotion: \(reduceMotion ? "TRUE ⚠️" : "false ✓")")
                .font(.caption.monospaced())
                .padding(4)
                .background(reduceMotion ? .red.opacity(0.8) : .green.opacity(0.5))
                .foregroundStyle(.white)
                .cornerRadius(4)
                .padding(.bottom, 100)
        }
        .padding(.top, 60)
    }

    // MARK: - Static Points (4x4 grid for reduce motion)

    private var staticPoints: [SIMD2<Float>] {
        var points: [SIMD2<Float>] = []
        for y in 0...3 {
            for x in 0...3 {
                points.append(SIMD2(Float(x) / 3.0, Float(y) / 3.0))
            }
        }
        return points
    }

    // MARK: - Aurora Animation

    /// 4x4 control points with organic, asymmetric motion
    /// CRITICAL: Edge points must stay ON the edges (x=0, x=1, y=0, y=1) to fill screen
    private func auroraPoints(time: Double) -> [SIMD2<Float>] {
        var points: [SIMD2<Float>] = []

        for y in 0...3 {
            for x in 0...3 {
                // Base grid position
                let baseX = Float(x) / 3.0
                let baseY = Float(y) / 3.0

                // Determine if this point is on an edge
                let isLeftEdge = x == 0
                let isRightEdge = x == 3
                let isTopEdge = y == 0
                let isBottomEdge = y == 3
                let isCorner = (isLeftEdge || isRightEdge) && (isTopEdge || isBottomEdge)

                // Corners: FIXED at exact corners to ensure full coverage
                if isCorner {
                    points.append(SIMD2(baseX, baseY))
                    continue
                }

                // ORGANIC MOTION: Multiple irrational frequency ratios for non-repeating animation
                let phi: Float = 1.618034      // Golden ratio
                let sqrt2: Float = 1.414214    // √2
                let sqrt3: Float = 1.732051    // √3
                let t = Float(time)

                // Per-point unique seed based on position (makes each point move differently)
                let pointSeed = Float(x * 7 + y * 13)  // Prime multipliers for variation

                // Edge points: can move ALONG the edge but not perpendicular to it
                let isEdge = isLeftEdge || isRightEdge || isTopEdge || isBottomEdge
                if isEdge {
                    // Multiple irrational frequencies + per-point variation = never repeats
                    let f1 = 0.23 * phi
                    let f2 = 0.19 * sqrt2
                    let f3 = 0.17 * sqrt3
                    let f4 = 0.13 * phi * sqrt2

                    let phase = pointSeed * 0.4
                    let edgeWave1 = sin(t * f1 + phase) * 0.08
                    let edgeWave2 = sin(t * f2 + phase * phi) * 0.05
                    let edgeWave3 = cos(t * f3 + phase * sqrt2) * 0.04
                    let edgeWave4 = sin(t * f4 + phase * 0.7) * 0.03

                    var finalX = baseX
                    var finalY = baseY

                    // Move along edge only (parallel to edge, not perpendicular)
                    if isTopEdge || isBottomEdge {
                        finalX = baseX + edgeWave1 + edgeWave2 + edgeWave3 + edgeWave4
                        finalX = max(0.08, min(0.92, finalX))
                    } else {
                        finalY = baseY + edgeWave1 + edgeWave2 + edgeWave3 + edgeWave4
                        finalY = max(0.08, min(0.92, finalY))
                    }

                    // Pin to actual edge
                    if isLeftEdge { finalX = 0 }
                    if isRightEdge { finalX = 1 }
                    if isTopEdge { finalY = 0 }
                    if isBottomEdge { finalY = 1 }

                    points.append(SIMD2(finalX, finalY))
                    continue
                }

                // Interior points (indices 5, 6, 9, 10): rich organic movement
                // Balanced amplitude - visible but won't create sharp borders
                let amplitude: Float = 0.22  // More visible motion

                // 5 wave components with irrational frequency ratios = virtually never repeats
                let phase = pointSeed * 0.3
                let xPhase = phase + 0.5  // X and Y use different phases
                let yPhase = phase * phi

                // X motion: unique combination of frequencies
                let xWave1 = sin(t * 0.21 * phi + xPhase)
                let xWave2 = sin(t * 0.17 * sqrt2 + xPhase * 1.3)
                let xWave3 = cos(t * 0.13 * sqrt3 + xPhase * 0.7)
                let xWave4 = sin(t * 0.11 * phi * sqrt2 + xPhase * phi)
                let xWave5 = cos(t * 0.07 * sqrt3 * phi + xPhase * 0.4)

                // Y motion: different frequency combination
                let yWave1 = cos(t * 0.19 * phi + yPhase)
                let yWave2 = sin(t * 0.23 * sqrt3 + yPhase * 1.2)
                let yWave3 = cos(t * 0.14 * sqrt2 + yPhase * 0.8)
                let yWave4 = sin(t * 0.09 * phi * sqrt3 + yPhase * phi)
                let yWave5 = sin(t * 0.06 * sqrt2 * phi + yPhase * 0.5)

                // Combine waves with varying weights
                let xMotion = (xWave1 * 0.35 + xWave2 * 0.25 + xWave3 * 0.20 + xWave4 * 0.12 + xWave5 * 0.08) * amplitude
                let yMotion = (yWave1 * 0.35 + yWave2 * 0.25 + yWave3 * 0.20 + yWave4 * 0.12 + yWave5 * 0.08) * amplitude

                // Constrain to safe zone - visible motion but maintains smooth gradients
                let finalX = min(baseX + 0.14, max(baseX - 0.14, baseX + xMotion))
                let finalY = min(baseY + 0.14, max(baseY - 0.14, baseY + yMotion))

                points.append(SIMD2(finalX, finalY))
            }
        }
        return points
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

    /// Smooth color interpolation using ease-in-out curve
    private func interpolateColor(_ from: Color, _ to: Color, fraction: CGFloat) -> Color {
        // Ease-in-out for smoother color transitions
        let t = Double(smoothstep(fraction))

        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]

        // Handle grayscale colors
        let fromR = fromComponents.count >= 3 ? fromComponents[0] : fromComponents[0]
        let fromG = fromComponents.count >= 3 ? fromComponents[1] : fromComponents[0]
        let fromB = fromComponents.count >= 3 ? fromComponents[2] : fromComponents[0]
        let fromA = fromComponents.count > 3 ? fromComponents[3] : 1.0

        let toR = toComponents.count >= 3 ? toComponents[0] : toComponents[0]
        let toG = toComponents.count >= 3 ? toComponents[1] : toComponents[0]
        let toB = toComponents.count >= 3 ? toComponents[2] : toComponents[0]
        let toA = toComponents.count > 3 ? toComponents[3] : 1.0

        return Color(
            red: fromR + (toR - fromR) * t,
            green: fromG + (toG - fromG) * t,
            blue: fromB + (toB - fromB) * t,
            opacity: fromA + (toA - fromA) * t
        )
    }

    /// Smoothstep function for ease-in-out interpolation
    private func smoothstep(_ x: CGFloat) -> CGFloat {
        let t = max(0, min(1, x))
        return t * t * (3 - 2 * t)
    }
}

// MARK: - Previews

#Preview("Aurora Mesh - Dashboard") {
    BreathingMeshBackground(scrollProgress: 0.0)
        .ignoresSafeArea()
}

#Preview("Aurora Mesh - Mid-scroll") {
    BreathingMeshBackground(scrollProgress: 1.5)
        .ignoresSafeArea()
}

#Preview("Aurora Mesh - Dark Mode") {
    BreathingMeshBackground(scrollProgress: 2.0)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
}

#Preview("Aurora Mesh - Insights") {
    BreathingMeshBackground(scrollProgress: 3.0)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
}
