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

    func backgroundTint(for colorScheme: ColorScheme) -> Color {
        switch (self, colorScheme) {
        // Light mode - warm cream tones
        case (.morning, .light): return Color(hex: "E8F4F8")
        case (.midday, .light): return Color(hex: "FFF8F0")
        case (.evening, .light): return Color(hex: "FFF5EB")
        case (.night, .light): return Color(hex: "F5F0EA")
        // Dark mode - warm charcoal tones
        case (.morning, .dark): return Color(hex: "1A1F22")
        case (.midday, .dark): return Color(hex: "1C1917")
        case (.evening, .dark): return Color(hex: "1F1A17")
        case (.night, .dark): return Color(hex: "171514")
        @unknown default: return Color(hex: "1C1917")
        }
    }

    // Legacy accessor for non-environment contexts
    var backgroundTint: Color {
        backgroundTint(for: .light)
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

// MARK: - Color Palette (Bloom's warm palette - Light/Dark adaptive)

enum Theme {
    // Primary colors - warm coral/sage/lavender (slightly brighter in dark mode)
    static let accent = Color.adaptive(light: "E88B7F", dark: "F4A99F")
    static let secondary = Color.adaptive(light: "7DB095", dark: "9DCAB0")
    static let tertiary = Color.adaptive(light: "B4A0C7", dark: "CFC0DC")
    static let warmPeach = Color.adaptive(light: "F4B5A0", dark: "F8CFC0")
    static let warmTaupe = Color.adaptive(light: "8B7E72", dark: "A89B8F")

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

    // Background palette - honeyed cream (light) / warm charcoal (dark)
    static let background = Color.adaptive(light: "FFF8F0", dark: "1C1917")
    static let surface = Color.adaptive(light: "FBF7F3", dark: "292524")
    static let surfaceElevated = Color.adaptive(light: "FFFFFF", dark: "3D3733")

    // Text colors - inverted for dark mode
    static let textPrimary = Color.adaptive(light: "3D3733", dark: "FAF7F5")
    static let textSecondary = Color.adaptive(light: "5A524A", dark: "D6CFC8")
    static let textMuted = Color.adaptive(light: "796E63", dark: "A89B8F")

    // Macro colors - warm, slightly boosted saturation in dark mode
    static let calories = Color.adaptive(light: "E89B7C", dark: "F4B09A")
    static let protein = Color.adaptive(light: "8BB4B8", dark: "A8CED2")
    static let carbs = Color.adaptive(light: "D9A67C", dark: "E8BFA0")
    static let fat = Color.adaptive(light: "C4B87C", dark: "D8CEA0")

    // Semantic colors
    static let success = Color.adaptive(light: "7DB095", dark: "9DCAB0")
    static let warning = Color.adaptive(light: "E9B879", dark: "F4CFA0")
    static let error = Color.adaptive(light: "D97C7C", dark: "E89A9A")
    static let warm = Color.adaptive(light: "F4B5A0", dark: "F8CFC0")
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
    @Environment(\.colorScheme) private var colorScheme

    // Light mode needs much higher opacity since pastel colors on cream background are subtle
    private var opacityMultiplier: Double {
        colorScheme == .dark ? 2.5 : 4.0
    }

    // Cap is higher for light mode to allow orbs to actually show
    private var opacityCap: Double {
        colorScheme == .dark ? 0.6 : 0.85
    }

    var body: some View {
        let timeOfDay = TimeOfDay.current
        let config = BackgroundConfig.forTab(currentTab)

        if reduceMotion {
            timeOfDay.backgroundTint(for: colorScheme)
        } else {
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate

                Canvas { context, size in
                    let w = size.width
                    let h = size.height

                    // Base background
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(timeOfDay.backgroundTint(for: colorScheme))
                    )

                    // Draw orbs with smooth radial gradients
                    for (index, orb) in config.orbs.enumerated() {
                        let phaseOffset = Double(index) * 2.1
                        let speedMult = orb.speed

                        // Position with organic motion
                        let x = orb.baseX * w + sin(time * speedMult + phaseOffset) * w * 0.15
                        let y = orb.baseY * h + cos(time * speedMult * 0.8 + phaseOffset) * h * 0.12

                        // Breathing opacity
                        let breathPhase = sin(time * 0.15 + phaseOffset * 0.5)
                        let breathOpacity = 0.85 + breathPhase * 0.15
                        let finalOpacity = min(opacityCap, orb.opacity * breathOpacity * timeOfDay.orbIntensity * opacityMultiplier)

                        let orbRadius = orb.size * min(w, h) * 0.3
                        let center = CGPoint(x: x, y: y)

                        // Many gradient stops for ultra-smooth falloff (reduces banding)
                        var stops: [Gradient.Stop] = []
                        let stepCount = 20
                        for i in 0...stepCount {
                            let t = Double(i) / Double(stepCount)
                            // Smooth cubic falloff curve
                            let opacity = finalOpacity * pow(1.0 - t, 2.5)
                            stops.append(.init(color: orb.color.opacity(opacity), location: t))
                        }
                        let gradient = Gradient(stops: stops)

                        // Draw large circle with radial gradient
                        let outerRadius = orbRadius * 2.5
                        let rect = CGRect(
                            x: center.x - outerRadius,
                            y: center.y - outerRadius,
                            width: outerRadius * 2,
                            height: outerRadius * 2
                        )

                        context.fill(
                            Circle().path(in: rect),
                            with: .radialGradient(
                                gradient,
                                center: center,
                                startRadius: 0,
                                endRadius: outerRadius
                            )
                        )
                    }

                    // Subtle noise overlay to break up any remaining banding
                    for _ in 0..<800 {
                        let nx = Double.random(in: 0...w)
                        let ny = Double.random(in: 0...h)
                        let noiseOpacity = Double.random(in: 0.01...0.025)
                        let noiseSize = Double.random(in: 1...2)
                        context.fill(
                            Circle().path(in: CGRect(x: nx, y: ny, width: noiseSize, height: noiseSize)),
                            with: .color(Color.white.opacity(noiseOpacity))
                        )
                    }
                }
            }
        }
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
        ZStack {
            // Outer glow pulse
            Circle()
                .fill(Theme.accent.opacity(0.3))
                .frame(width: 16, height: 16)
                .scaleEffect(isBreathing ? 1.5 : 0.8)
                .opacity(isBreathing ? 0 : 0.6)

            // Inner dot
            Circle()
                .fill(Theme.accent)
                .frame(width: 10, height: 10)
                .shadow(color: Theme.accent.opacity(0.6), radius: isBreathing ? 8 : 4)
                .scaleEffect(isBreathing ? 1.15 : 0.85)
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isBreathing)
        .onAppear { isBreathing = true }
    }
}

struct StreamingWave: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.accentGradient)
                        .frame(width: 4, height: barHeight(for: i, time: time))
                }
            }
        }
        .frame(height: 20)
    }

    private func barHeight(for index: Int, time: Double) -> CGFloat {
        let offset = Double(index) * 0.5
        let wave1 = sin(time * 3.0 + offset) * 4
        let wave2 = sin(time * 5.0 + offset * 1.3) * 2
        return 8 + wave1 + wave2
    }
}

/// More dramatic thinking indicator with orbiting dots
struct ThinkingOrbs: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Center breathing glow
            Circle()
                .fill(Theme.accent.opacity(0.2))
                .frame(width: 24, height: 24)
                .blur(radius: 8)

            // Orbiting dots
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 6, height: 6)
                    .offset(x: 14)
                    .rotationEffect(.degrees(rotation + Double(i) * 120))
                    .opacity(0.6 + Double(i) * 0.15)
            }
        }
        .frame(width: 36, height: 36)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
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

    /// Staggered entrance animation for lists
    func staggeredReveal(index: Int) -> some View {
        self.scrollTransition(.interactive) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0)
                .scaleEffect(phase.isIdentity ? 1 : 0.92)
                .offset(y: phase.isIdentity ? 0 : 20)
        }
        .animation(.bloom.delay(Double(index) * 0.05), value: index)
    }
}

// MARK: - Scroll Offset Tracking

struct ScrollOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// A view that reports its scroll offset
struct ScrollOffsetReader: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: -geo.frame(in: .named("scroll")).minY
                )
        }
        .frame(height: 0)
    }
}

// MARK: - Scrollytelling Hero Header

struct ScrollytellingHero<Content: View>: View {
    let scrollOffset: CGFloat
    let expandedHeight: CGFloat
    let collapsedHeight: CGFloat
    @ViewBuilder let expanded: () -> Content
    @ViewBuilder let collapsed: () -> Content

    private var progress: CGFloat {
        min(1, max(0, scrollOffset / (expandedHeight - collapsedHeight)))
    }

    var body: some View {
        ZStack {
            expanded()
                .opacity(1 - progress)
                .scaleEffect(1 - progress * 0.1)

            collapsed()
                .opacity(progress)
                .scaleEffect(0.9 + progress * 0.1)
        }
        .frame(height: expandedHeight - (expandedHeight - collapsedHeight) * progress)
        .animation(.bloomSubtle, value: progress)
    }
}

// MARK: - Shimmer Text (Loading States)

struct ShimmerText: View {
    let text: String
    var font: Font = .title2.weight(.medium)

    @State private var shimmerProgress: CGFloat = 0

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(Theme.textSecondary)
            .background(
                GeometryReader { geo in
                    // Shimmer gradient that spans full text width plus overflow
                    LinearGradient(
                        colors: [
                            .clear,
                            .clear,
                            Theme.accent.opacity(0.8),
                            Theme.warmPeach,
                            Theme.accent.opacity(0.8),
                            .clear,
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)  // Shimmer band is 50% of text width
                    .offset(x: -geo.size.width * 0.25 + shimmerProgress * geo.size.width * 1.5)
                    .mask {
                        Text(text)
                            .font(font)
                    }
                }
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    shimmerProgress = 1
                }
            }
    }
}

/// Centered loading view with shimmer text
struct ShimmerLoadingView: View {
    let text: String

    var body: some View {
        VStack {
            Spacer()
            ShimmerText(text: text)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Color Helpers

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

    /// Creates an adaptive color that automatically switches between light and dark mode
    static func adaptive(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}
