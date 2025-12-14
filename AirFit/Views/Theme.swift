import SwiftUI

// MARK: - AirFit Design System (Bloom-inspired)
// Philosophy: "Like a warm, supportive best friend"
// Warmth through restraint, organic motion, hospitality-first

// MARK: - Time of Day System

enum TimeOfDay {
    case morning    // 5am - 10am
    case midday     // 10am - 4pm
    case evening    // 4pm - 8pm
    case night      // 8pm - 5am

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return .morning
        case 10..<16: return .midday
        case 16..<20: return .evening
        default: return .night
        }
    }

    var backgroundTint: Color {
        switch self {
        case .morning: return Color(hex: "E8F4F8")  // Cool, crisp
        case .midday: return Color(hex: "FFF8F0")   // Neutral warmth (honeyed cream)
        case .evening: return Color(hex: "FFF5EB")  // Warmer softening
        case .night: return Color(hex: "F5F0EA")    // Twilight, restful
        }
    }

    var orbIntensity: Double {
        switch self {
        case .morning: return 1.0
        case .midday: return 1.0
        case .evening: return 0.9
        case .night: return 0.7
        }
    }
}

// MARK: - Color Palette (Bloom's warm palette)

enum Theme {
    // Primary colors - warm coral/sage/lavender
    static let accent = Color(hex: "E88B7F")        // Warm coral (Bloom's signature)
    static let secondary = Color(hex: "7DB095")     // Sage green (calming wellness)
    static let tertiary = Color(hex: "B4A0C7")      // Dusty lavender (contemplative)
    static let warmPeach = Color(hex: "F4B5A0")     // Encouragement & celebration
    static let warmTaupe = Color(hex: "8B7E72")     // Grounding neutral

    // Gradient
    static let accentGradient = LinearGradient(
        colors: [accent, warmPeach],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let softGradient = LinearGradient(
        colors: [
            accent.opacity(0.12),
            secondary.opacity(0.08),
            tertiary.opacity(0.06)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Background palette - honeyed cream
    static let background = Color(hex: "FFF8F0")    // Honeyed cream foundation
    static let surface = Color(hex: "FBF7F3")       // Slightly elevated warm white
    static let surfaceElevated = Color(hex: "FFFFFF")

    // Text colors - soft charcoal, WCAG compliant
    static let textPrimary = Color(hex: "3D3733")   // Soft charcoal
    static let textSecondary = Color(hex: "5A524A") // Medium warmth
    static let textMuted = Color(hex: "796E63")     // Warm taupe (WCAG AA)

    // Macro colors - warm, not clinical
    static let calories = Color(hex: "E89B7C")      // Warm coral
    static let protein = Color(hex: "8BB4B8")       // Blue-green sibling to sage
    static let carbs = Color(hex: "D9A67C")         // Warm gold
    static let fat = Color(hex: "C4B87C")           // Muted yellow

    // Semantic colors
    static let success = Color(hex: "7DB095")       // Sage green
    static let warning = Color(hex: "E9B879")       // Warm gold
    static let error = Color(hex: "D97C7C")         // Muted red
    static let warm = Color(hex: "F4B5A0")          // Warm peach
}

// MARK: - Typography (Three-tier Bloom system)

extension Font {
    // Display - New York Serif (The Wise Counselor)
    static let displayLarge = Font.system(size: 34, weight: .medium, design: .serif)
    static let displayMedium = Font.system(size: 24, weight: .regular, design: .serif)

    // Headlines - SF Rounded (The Warm Encourager)
    static let headlineLarge = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headlineMedium = Font.system(size: 17, weight: .medium, design: .rounded)
    static let numeric = Font.system(size: 17, weight: .medium, design: .rounded)

    // Hero numbers - Large rounded for impact
    static let metricHero = Font.system(size: 64, weight: .bold, design: .rounded)
    static let metricLarge = Font.system(size: 48, weight: .semibold, design: .rounded)
    static let metricMedium = Font.system(size: 32, weight: .medium, design: .rounded)
    static let metricSmall = Font.system(size: 24, weight: .medium, design: .rounded)

    // Body - SF Default (The Reliable Companion)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)

    // Labels
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 13, weight: .regular, design: .default)
    static let labelHero = Font.system(size: 11, weight: .semibold, design: .default)
    static let labelMicro = Font.system(size: 10, weight: .medium, design: .default)

    // Caption
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    // Display titles
    static let titleLarge = Font.system(size: 28, weight: .bold, design: .rounded)
    static let titleMedium = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let sectionHeader = Font.system(size: 13, weight: .semibold, design: .default)
}

// MARK: - Animation System (Bloom's organic motion)

extension Animation {
    // Primary spring - "gentle but not sluggish"
    static var bloom: Animation {
        .spring(response: 0.6, dampingFraction: 0.82, blendDuration: 0.25)
    }

    // Faster, subtle (checks, pills, micro-interactions)
    static var bloomSubtle: Animation {
        .spring(response: 0.45, dampingFraction: 0.88, blendDuration: 0.15)
    }

    // Slow, ambient breathing (Kenya Hara's breath cycle)
    static var bloomBreathing: Animation {
        .timingCurve(0.25, 0.1, 0.25, 1.0, duration: 8.0)
    }

    // Water-like settling effect
    static var bloomWater: Animation {
        .timingCurve(0.4, 0.0, 0.2, 1, duration: 0.8)
    }

    // Petal falling (organic downward motion)
    static var bloomPetal: Animation {
        .timingCurve(0.33, 0.0, 0.2, 1, duration: 1.5)
    }

    // Soft breeze (unhurried, drifting)
    static var breeze: Animation {
        .spring(response: 0.85, dampingFraction: 0.92, blendDuration: 0.5)
    }

    // Shapeshifting background (liquid transition)
    static var shapeshift: Animation {
        .timingCurve(0.25, 0.1, 0.25, 1.0, duration: 1.4)
    }

    // Storytelling (tab transitions)
    static var storytelling: Animation {
        .timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.7)
    }

    // Legacy aliases for compatibility
    static var airfit: Animation { bloom }
    static var airfitSubtle: Animation { bloomSubtle }
    static var airfitData: Animation { bloomWater }
    static var airfitMorph: Animation { shapeshift }
    static var airfitBreathing: Animation { bloomBreathing }
    static var airfitCelebrate: Animation { .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.3) }

    /// Staggered entrance
    static func stagger(_ index: Int) -> Animation {
        bloom.delay(Double(index) * 0.08)
    }
}

// MARK: - Ethereal Background (Bloom-style organic orbs)

struct EtherealBackground: View {
    var currentTab: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            // Static warm gradient for reduced motion
            LinearGradient(
                colors: [Theme.background, Theme.surface],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let timeOfDay = TimeOfDay.current
                    let config = BackgroundConfig.forTab(currentTab)

                    // Draw time-of-day tinted base
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(timeOfDay.backgroundTint)
                    )

                    // Draw each orb with organic motion
                    for (index, orb) in config.orbs.enumerated() {
                        drawOrb(
                            context: context,
                            size: size,
                            time: time,
                            orb: orb,
                            index: index,
                            intensity: timeOfDay.orbIntensity
                        )
                    }
                }
            }
        }
    }

    private func drawOrb(
        context: GraphicsContext,
        size: CGSize,
        time: Double,
        orb: OrbState,
        index: Int,
        intensity: Double
    ) {
        let w = size.width
        let h = size.height

        // Multi-wave organic motion (not mechanical sine)
        let speedMult = orb.speed
        let phaseOffset = Double(index) * 2.1

        // Primary motion layer
        let primaryX = orb.baseX * w + sin(time * speedMult + phaseOffset) * w * 0.15
        let primaryY = orb.baseY * h + cos(time * speedMult * 0.8 + phaseOffset) * h * 0.12

        // Secondary wobble - different frequency
        let wobbleX = sin(time * speedMult * 2.3 + phaseOffset + 1.2) * w * orb.wobble * 0.04
        let wobbleY = cos(time * speedMult * 1.9 + phaseOffset + 2.1) * h * orb.wobble * 0.03

        // Tertiary micro-drift - very slow
        let microX = sin(time * 0.05 + phaseOffset * 3.7) * w * 0.02
        let microY = cos(time * 0.04 + phaseOffset * 5.3) * h * 0.015

        let x = primaryX + wobbleX + microX
        let y = primaryY + wobbleY + microY

        // Breathing opacity (0.70-1.0 range)
        let breathPhase = sin(time * 0.15 + phaseOffset * 0.5)
        let breathingOpacity = 0.85 + breathPhase * 0.15

        let orbSize = orb.size * min(w, h) * 0.4
        let rect = CGRect(
            x: x - orbSize / 2,
            y: y - orbSize / 2,
            width: orbSize,
            height: orbSize
        )

        // Draw with blur
        var blurredContext = context
        blurredContext.addFilter(.blur(radius: orb.blur))
        blurredContext.fill(
            Circle().path(in: rect),
            with: .color(orb.color.opacity(orb.opacity * breathingOpacity * intensity))
        )
    }
}

// MARK: - Background Configuration Per Tab

struct OrbState {
    let color: Color
    let baseX: CGFloat
    let baseY: CGFloat
    let size: CGFloat
    let opacity: Double
    let blur: CGFloat
    let speed: Double
    let wobble: Double
}

struct BackgroundConfig {
    let orbs: [OrbState]

    static func forTab(_ tab: Int) -> BackgroundConfig {
        switch tab {
        case 0: // Coach - Warm coral anchor (communicative)
            return BackgroundConfig(orbs: [
                OrbState(color: Theme.accent, baseX: 0.2, baseY: 0.3, size: 1.2, opacity: 0.18, blur: 100, speed: 0.08, wobble: 0.4),
                OrbState(color: Theme.warmPeach, baseX: 0.8, baseY: 0.6, size: 0.9, opacity: 0.14, blur: 85, speed: 0.12, wobble: 0.35),
                OrbState(color: Theme.tertiary, baseX: 0.5, baseY: 0.85, size: 0.7, opacity: 0.10, blur: 70, speed: 0.15, wobble: 0.5)
            ])
        case 1: // Nutrition - Sage green emphasis (vitality)
            return BackgroundConfig(orbs: [
                OrbState(color: Theme.secondary, baseX: 0.3, baseY: 0.25, size: 1.1, opacity: 0.16, blur: 100, speed: 0.09, wobble: 0.45),
                OrbState(color: Theme.calories, baseX: 0.75, baseY: 0.5, size: 0.85, opacity: 0.12, blur: 85, speed: 0.11, wobble: 0.4),
                OrbState(color: Theme.warmPeach, baseX: 0.4, baseY: 0.8, size: 0.65, opacity: 0.10, blur: 70, speed: 0.14, wobble: 0.5)
            ])
        case 2: // Insights - Lavender/blue (wisdom, contemplative)
            return BackgroundConfig(orbs: [
                OrbState(color: Theme.tertiary, baseX: 0.25, baseY: 0.35, size: 1.15, opacity: 0.17, blur: 100, speed: 0.07, wobble: 0.35),
                OrbState(color: Theme.protein, baseX: 0.7, baseY: 0.55, size: 0.9, opacity: 0.13, blur: 85, speed: 0.10, wobble: 0.4),
                OrbState(color: Theme.accent, baseX: 0.5, baseY: 0.82, size: 0.6, opacity: 0.09, blur: 70, speed: 0.13, wobble: 0.45)
            ])
        case 3: // Profile - Taupe/peach (grounded, personal)
            return BackgroundConfig(orbs: [
                OrbState(color: Theme.warmPeach, baseX: 0.3, baseY: 0.28, size: 1.0, opacity: 0.15, blur: 100, speed: 0.08, wobble: 0.4),
                OrbState(color: Theme.warmTaupe, baseX: 0.75, baseY: 0.5, size: 0.8, opacity: 0.11, blur: 85, speed: 0.11, wobble: 0.35),
                OrbState(color: Theme.accent, baseX: 0.45, baseY: 0.78, size: 0.55, opacity: 0.08, blur: 70, speed: 0.14, wobble: 0.5)
            ])
        default: // Settings - Neutral, muted (calm, functional)
            return BackgroundConfig(orbs: [
                OrbState(color: Theme.warmTaupe, baseX: 0.35, baseY: 0.3, size: 0.9, opacity: 0.12, blur: 100, speed: 0.06, wobble: 0.3),
                OrbState(color: Theme.surface, baseX: 0.7, baseY: 0.55, size: 0.7, opacity: 0.10, blur: 85, speed: 0.09, wobble: 0.35),
                OrbState(color: Theme.tertiary.opacity(0.5), baseX: 0.5, baseY: 0.8, size: 0.5, opacity: 0.08, blur: 70, speed: 0.12, wobble: 0.4)
            ])
        }
    }
}

// MARK: - AI Presence Indicators

struct BreathingDot: View {
    @State private var isBreathing = false

    var body: some View {
        Circle()
            .fill(Theme.accent)
            .frame(width: 8, height: 8)
            .shadow(color: Theme.accent.opacity(0.4), radius: isBreathing ? 6 : 3)
            .scaleEffect(isBreathing ? 1.1 : 0.9)
            .animation(.bloomBreathing.repeatForever(autoreverses: true), value: isBreathing)
            .onAppear { isBreathing = true }
    }
}

struct StreamingWave: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.accentGradient)
                    .frame(width: 3, height: barHeight(for: i))
            }
        }
        .frame(height: 16)
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let offset = CGFloat(index) * 0.4
        return 6 + sin(phase + offset) * 5
    }
}

// MARK: - Animated Number

struct AnimatedNumber: View {
    let value: Int
    var showSign: Bool = false

    var body: some View {
        Text(showSign && value >= 0 ? "+\(value)" : "\(value)")
            .contentTransition(.numericText(value: Double(value)))
            .animation(.bloomSubtle, value: value)
    }
}

// MARK: - Card Style Modifier (Bloom-style)

struct BloomCardStyle: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(
                        color: .black.opacity(elevated ? 0.05 : 0.02),
                        radius: elevated ? 12 : 8,
                        x: 0,
                        y: elevated ? 4 : 2
                    )
            )
    }
}

extension View {
    func bloomCard(elevated: Bool = false) -> some View {
        modifier(BloomCardStyle(elevated: elevated))
    }
}

// MARK: - Progress Bars

struct ThemedProgressBar: View {
    let label: String
    let current: Int
    let target: Int
    var unit: String = ""
    var color: Color = Theme.accent

    @State private var animatedProgress: CGFloat = 0
    @State private var showPop = false

    private var progress: CGFloat {
        guard target > 0 else { return 0 }
        return min(1.0, CGFloat(current) / CGFloat(target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(current)")
                        .font(.numeric)
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: Double(current)))

                    Text("/\(target)\(unit)")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * animatedProgress, height: 8)
                        .shadow(color: color.opacity(showPop ? 0.4 : 0), radius: showPop ? 8 : 0)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            withAnimation(.bloomWater) {
                animatedProgress = progress
            }
        }
        .onChange(of: current) { oldValue, newValue in
            withAnimation(.bloomWater) {
                animatedProgress = progress
            }
            if newValue > oldValue {
                withAnimation(.bloomSubtle) { showPop = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.bloomSubtle) { showPop = false }
                }
            }
        }
    }
}

struct HeroProgressBar: View {
    let label: String
    let current: Int
    let target: Int
    var unit: String = ""
    var color: Color = Theme.accent

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        guard target > 0 else { return 0 }
        return min(1.0, CGFloat(current) / CGFloat(target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(label.uppercased())
                    .font(.labelHero)
                    .tracking(1.5)
                    .foregroundStyle(Theme.textMuted)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(current)")
                        .font(.metricSmall)
                        .foregroundStyle(color)
                        .contentTransition(.numericText(value: Double(current)))

                    Text("/\(target)\(unit)")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedProgress, height: 12)
                }
            }
            .frame(height: 12)
        }
        .onAppear {
            withAnimation(.bloomWater) {
                animatedProgress = progress
            }
        }
        .onChange(of: current) { _, _ in
            withAnimation(.bloomWater) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Stat Pill (for health context)

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = Theme.accent

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            Text(value)
                .font(.numeric)
                .foregroundStyle(Theme.textPrimary)

            Text(label)
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Button Styles

struct BloomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.bloom, value: configuration.isPressed)
    }
}

struct AirFitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.bloom, value: configuration.isPressed)
    }
}

struct AirFitSubtleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.bloomSubtle, value: configuration.isPressed)
    }
}

// MARK: - View Modifiers

extension View {
    func scrollReveal() -> some View {
        self.scrollTransition(.interactive) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.4)
                .scaleEffect(phase.isIdentity ? 1 : 0.96)
                .offset(y: phase.isIdentity ? 0 : 8)
                .blur(radius: phase.isIdentity ? 0 : 2)
        }
    }

    func scrollHero() -> some View {
        self.scrollTransition(.interactive) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.5)
                .scaleEffect(phase.isIdentity ? 1 : 0.9)
                .blur(radius: phase.isIdentity ? 0 : 2)
        }
    }
}

// MARK: - Transitions

extension AnyTransition {
    static var breezeIn: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: 0.96))
                .combined(with: .offset(y: 8)),
            removal: .opacity
                .combined(with: .scale(scale: 0.98))
        )
    }
}

// MARK: - Color Hex Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
