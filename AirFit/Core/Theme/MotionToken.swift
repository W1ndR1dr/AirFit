import SwiftUI

/// Standardized motion and animation constants for consistent feel across AirFit
enum MotionToken {
    // MARK: - Letter Cascade Animation

    /// Total duration for cascade animation block
    static let cascadeDuration: Double = 1.2

    /// Base delay between letter animations (modified by sine curve)
    static let cascadeStagger: Double = 0.08

    /// Vertical offset for letter entrance
    static let cascadeOffsetY: CGFloat = 20

    /// SF Pro Variable weight animation range
    static let cascadeWeightFrom: CGFloat = 200
    static let cascadeWeightTo: CGFloat = 500

    // MARK: - Spring Animations

    /// Standard spring for UI elements - organic and responsive
    static let standardSpring = Animation.interpolatingSpring(
        stiffness: 130,
        damping: 12
    )

    /// Bouncy spring for delightful moments
    static let bouncySpring = Animation.interpolatingSpring(
        stiffness: 170,
        damping: 10
    )

    /// Gentle spring for subtle movements
    static let gentleSpring = Animation.interpolatingSpring(
        stiffness: 100,
        damping: 15
    )

    // MARK: - Timing Curves

    /// Micro-interactions (0.12s - 0.3s)
    static let microDuration: Double = 0.2
    static let microAnimation = Animation.snappy(duration: microDuration)

    /// Content transitions (0.6s)
    static let contentDuration: Double = 0.6
    static let contentAnimation = Animation.smooth(duration: contentDuration)

    /// Gradient cross-fades (0.6s)
    static let gradientDuration: Double = 0.6
    static let gradientAnimation = Animation.bouncy(duration: gradientDuration, extraBounce: 0.2)

    // MARK: - Glass Card Entrance

    /// Scale for card entrance animation
    static let cardEntranceScale: CGFloat = 0.96

    /// Opacity for card entrance
    static let cardEntranceOpacity: Double = 0.7

    // MARK: - Haptic Timing

    /// Delay before haptic feedback on press
    static let hapticDelay: Double = 0.05

    // MARK: - Physics Constants

    /// Velocity threshold for flick dismissal
    static let flickVelocityThreshold: CGFloat = 500

    /// Deceleration rate for physics-based animations
    static let decelerationRate: CGFloat = 0.998

    // MARK: - Performance Thresholds

    /// Maximum blur layers per screen for 120fps
    static let maxBlurLayers: Int = 6

    /// Target frame time for 120Hz displays (in seconds)
    static let targetFrameTime: Double = 1.0 / 120.0

    /// Acceptable frame drop threshold
    static let acceptableFrameDrops: Int = 2
}

// MARK: - Animation Extensions

extension Animation {
    /// Standard spring animation used throughout the app
    static var standard: Animation {
        MotionToken.standardSpring
    }

    /// Bouncy spring for delightful interactions
    static var bouncy: Animation {
        MotionToken.bouncySpring
    }

    /// Gentle spring for subtle movements
    static var gentle: Animation {
        MotionToken.gentleSpring
    }
}

// MARK: - Transition Extensions

extension AnyTransition {
    /// Standard screen transition with opacity and offset
    static var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 12)),
            removal: .opacity.combined(with: .offset(y: -12))
        )
    }

    /// Card entrance transition with scale and opacity
    static var cardEntrance: AnyTransition {
        .scale(scale: MotionToken.cardEntranceScale)
            .combined(with: .opacity)
    }

    /// Glass morphism fade for overlays
    static var glassFade: AnyTransition {
        .opacity.animation(MotionToken.contentAnimation)
    }
}

// MARK: - Helpers

extension MotionToken {
    /// Calculates staggered delay for cascade animations using sine curve
    /// Creates faster animation in the middle, slower at edges
    static func cascadeDelay(for index: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        let normalizedIndex = Double(index) / Double(total)
        let sineValue = sin(normalizedIndex * .pi)
        return sineValue * cascadeStagger * Double(total)
    }

    /// Determines if device supports ProMotion (120Hz)
    @MainActor
    static var supportsProMotion: Bool {
        return UIScreen.main.maximumFramesPerSecond > 60
    }

    /// Adjusts animation parameters for 60Hz displays
    @MainActor
    static func adjustedDamping(base: CGFloat) -> CGFloat {
        supportsProMotion ? base : base * 0.875
    }
}