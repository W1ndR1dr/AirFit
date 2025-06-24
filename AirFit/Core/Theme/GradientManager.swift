import SwiftUI

/// Manages gradient transitions with circadian awareness
/// Creates a journey through color spaces that adapts to time of day
@MainActor
final class GradientManager: ObservableObject {
    // MARK: - Properties
    
    /// Currently active gradient token
    @Published private(set) var active: GradientToken = .peachRose
    
    /// Transition animation in progress
    @Published private(set) var isTransitioning = false
    
    /// Extract accent color from current gradient
    @Published private(set) var accent: Color = Color.accentColor
    
    // MARK: - Gradient Pools
    
    /// Morning gradients (5 AM - 10 AM) - energizing, fresh
    private let morningGradients: [GradientToken] = [
        .mintAqua,
        .butterLemon,
        .sproutMint,
        .peachRose
    ]
    
    /// Evening gradients (6 PM - 11 PM, 12 AM - 4 AM) - calming, reflective  
    private let eveningGradients: [GradientToken] = [
        .lilacBlush,
        .duskBerry,
        .rosewoodPlum,
        .skyLavender
    ]
    
    /// All-day gradients (11 AM - 5 PM) - balanced, versatile
    private let allDayGradients: [GradientToken] = [
        .sageMelon,
        .icePeriwinkle,
        .coralMist,
        .dawnPeach
    ]
    
    /// History to prevent immediate repeats
    private var recentGradients: [GradientToken] = []
    private let historySize = 3
    
    /// Sunrise sequence for onboarding journey
    private let sunriseSequence: [GradientToken] = [
        .nightSky,
        .earlyTwilight,
        .morningTwilight,
        .firstLight,
        .sunrise,
        .morningGlow
    ]
    
    // MARK: - Initialization
    
    init() {
        // Start with a time-appropriate gradient
        selectInitialGradient()
    }
    
    // MARK: - Public Methods
    
    enum AdvanceStyle {
        case random      // Time-based pool selection
        case sunrise     // Sequential sunrise journey
        case idle        // Slow ambient drift
    }
    
    /// Advances to the next gradient with smooth transition
    /// - Parameter style: The advancement style (random, sunrise, or idle)
    func advance(style: AdvanceStyle = .random) {
        guard !isTransitioning else { return }
        
        let next: GradientToken?
        
        switch style {
        case .random:
            let pool = getCurrentPool()
            var candidates = pool.filter { !recentGradients.contains($0) }
            
            // If all gradients in pool were recently used, allow repeats but exclude current
            if candidates.isEmpty {
                candidates = pool.filter { $0 != active }
            }
            
            // Fallback to any gradient except current if needed
            if candidates.isEmpty {
                candidates = GradientToken.allCases.filter { $0 != active }
            }
            
            next = candidates.randomElement()
            
        case .sunrise:
            // Find current position in sunrise sequence
            if let currentIndex = sunriseSequence.firstIndex(of: active),
               currentIndex < sunriseSequence.count - 1 {
                next = sunriseSequence[currentIndex + 1]
            } else {
                // If not in sequence or at end, start from beginning
                next = sunriseSequence.first
            }
            
        case .idle:
            // For idle, pick from a calm subset
            let idlePool: [GradientToken] = [.skyLavender, .lilacBlush, .icePeriwinkle, .dawnPeach]
            next = idlePool.filter { $0 != active }.randomElement()
        }
        
        guard let selectedGradient = next else { return }
        
        // Update history
        recentGradients.append(selectedGradient)
        if recentGradients.count > historySize {
            recentGradients.removeFirst()
        }
        
        // Animate transition
        isTransitioning = true
        withAnimation(.easeInOut(duration: 0.6)) {
            active = selectedGradient
            updateAccentColor()
        }
        
        // Reset transition flag after animation
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            isTransitioning = false
        }
    }
    
    /// Forces a specific gradient (useful for onboarding or special states)
    func setGradient(_ token: GradientToken, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.6)) {
                active = token
                updateAccentColor()
            }
        } else {
            active = token
            updateAccentColor()
        }
        
        // Add to history to prevent immediate repeat
        recentGradients.append(token)
        if recentGradients.count > historySize {
            recentGradients.removeFirst()
        }
    }
    
    /// Returns a gradient appropriate for current time
    func suggestedGradient() -> GradientToken {
        getCurrentPool().randomElement() ?? .peachRose
    }
    
    // MARK: - Private Methods
    
    private func selectInitialGradient() {
        active = suggestedGradient()
        recentGradients = [active]
        updateAccentColor()
    }
    
    /// Updates the accent color based on the current gradient
    private func updateAccentColor() {
        // Get the gradient colors for current color scheme
        let colors = active.colors(for: .light) // Use light mode for accent extraction
        
        // Extract the last color (usually the more vibrant one) and adjust opacity
        if let lastColor = colors.last {
            accent = lastColor.opacity(0.9)
        } else {
            accent = Color.accentColor
        }
    }
    
    private func getCurrentPool() -> [GradientToken] {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5...10:
            return morningGradients
        case 18...23, 0...4:
            return eveningGradients
        default:
            return allDayGradients
        }
    }
    
    /// Gets the current linear gradient for the active token
    func currentGradient(for colorScheme: ColorScheme) -> LinearGradient {
        active.linearGradient(for: colorScheme)
    }
    
    /// Gets the current radial gradient for special effects
    func currentRadialGradient(for colorScheme: ColorScheme) -> RadialGradient {
        active.radialGradient(for: colorScheme)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies the current gradient as a background
    func gradientBackground() -> some View {
        modifier(GradientBackgroundModifier())
    }
}

struct GradientBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    
    func body(content: Content) -> some View {
        content
            .background(
                gradientManager.currentGradient(for: colorScheme)
                    .ignoresSafeArea()
            )
    }
}
