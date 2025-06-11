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
    
    // MARK: - Initialization
    
    init() {
        // Start with a time-appropriate gradient
        selectInitialGradient()
    }
    
    // MARK: - Public Methods
    
    /// Advances to the next gradient with smooth transition
    /// Uses circadian-aware selection and prevents repeats
    func advance() {
        guard !isTransitioning else { return }
        
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
        
        guard let next = candidates.randomElement() else { return }
        
        // Update history
        recentGradients.append(next)
        if recentGradients.count > historySize {
            recentGradients.removeFirst()
        }
        
        // Animate transition
        isTransitioning = true
        withAnimation(.easeInOut(duration: 0.6)) {
            active = next
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
            }
        } else {
            active = token
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