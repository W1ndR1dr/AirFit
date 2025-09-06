import SwiftUI

/// Voice input visualization with expanding ripple animation
/// Creates a beautiful, calming effect when recording
struct MicRippleView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0.0
    @State private var secondaryRippleScale: CGFloat = 0.5
    @State private var secondaryRippleOpacity: Double = 0.0
    @State private var isAnimating = false

    let isRecording: Bool
    let size: CGFloat

    init(
        isRecording: Bool = false,
        size: CGFloat = 120
    ) {
        self.isRecording = isRecording
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background ripples
            if isRecording {
                Circle()
                    .stroke(
                        gradientManager.currentGradient(for: colorScheme),
                        lineWidth: 2
                    )
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)

                Circle()
                    .stroke(
                        gradientManager.currentGradient(for: colorScheme),
                        lineWidth: 1.5
                    )
                    .scaleEffect(secondaryRippleScale)
                    .opacity(secondaryRippleOpacity)
            }

            // Center microphone icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.white.opacity(0.3),
                                lineWidth: 1
                            )
                    )

                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.system(size: size * 0.3, weight: .medium))
                    .foregroundStyle(
                        isRecording
                            ? AnyShapeStyle(gradientManager.currentGradient(for: colorScheme))
                            : AnyShapeStyle(Color.primary.opacity(0.6))
                    )
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isRecording)
            }
            .frame(width: size, height: size)
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                radius: 10,
                x: 0,
                y: 4
            )
        }
        .frame(width: size * 2, height: size * 2)
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startRippleAnimation()
            } else {
                stopRippleAnimation()
            }
        }
        .onAppear {
            if isRecording {
                startRippleAnimation()
            }
        }
    }

    private func startRippleAnimation() {
        isAnimating = true

        // Primary ripple
        withAnimation(
            Animation.easeOut(duration: 2.0)
                .repeatForever(autoreverses: false)
        ) {
            rippleScale = 2.0
            rippleOpacity = 0.0
        }

        // Delayed secondary ripple
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isAnimating {
                withAnimation(
                    Animation.easeOut(duration: 2.0)
                        .repeatForever(autoreverses: false)
                ) {
                    secondaryRippleScale = 2.0
                    secondaryRippleOpacity = 0.0
                }
            }
        }

        // Initial opacity animation
        withAnimation(.easeIn(duration: 0.3)) {
            rippleOpacity = 0.6
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isAnimating {
                withAnimation(.easeIn(duration: 0.3)) {
                    secondaryRippleOpacity = 0.4
                }
            }
        }
    }

    private func stopRippleAnimation() {
        isAnimating = false

        withAnimation(.easeOut(duration: 0.3)) {
            rippleScale = 0.5
            rippleOpacity = 0.0
            secondaryRippleScale = 0.5
            secondaryRippleOpacity = 0.0
        }
    }
}

// MARK: - Voice Input Button

struct VoiceInputButton: View {
    @State private var isPressed = false

    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        MicRippleView(isRecording: isRecording)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture {
                HapticService.impact(.medium)

                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                    action()
                }
            }
    }
}
