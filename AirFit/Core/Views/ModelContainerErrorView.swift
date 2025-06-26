import SwiftUI

struct ModelContainerErrorView: View {
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme)
    private var colorScheme
    @State private var animateIn = false

    let error: Error
    let isRetrying: Bool
    let onRetry: () -> Void
    let onReset: () -> Void
    let onUseInMemory: () -> Void

    var body: some View {
        BaseScreen {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                // Error icon and title
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "exclamationmark.icloud.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(animateIn ? 1 : 0.5)
                        .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                    CascadeText("Database Error")
                        .font(.system(size: 32, weight: .thin, design: .rounded))

                    Text("We couldn't load your data")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .opacity(animateIn ? 1 : 0)
                        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
                }

                // Error details
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Error Details:")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)

                        Text(error.localizedDescription)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .opacity(animateIn ? 1 : 0)
                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                Spacer()

                // Recovery options
                VStack(spacing: AppSpacing.md) {
                    Button(action: {
                        HapticService.impact(.medium)
                        onRetry()
                    }, label: {
                        HStack(spacing: AppSpacing.sm) {
                            if isRetrying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            Text("Try Again")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 12, y: 4)
                    })
                    .disabled(isRetrying)

                    Button(action: {
                        HapticService.impact(.rigid)
                        onReset()
                    }, label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .medium))
                            Text("Reset Database")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.9), Color.red.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.orange.opacity(0.3), radius: 12, y: 4)
                    })
                    .disabled(isRetrying)

                    Button(action: {
                        HapticService.impact(.light)
                        onUseInMemory()
                    }, label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "memorychip")
                                .font(.system(size: 18, weight: .medium))
                            Text("Continue Without Saving")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    })
                    .disabled(isRetrying)

                    Text("'Continue Without Saving' will let you use the app, but your data won't be saved when you close it.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.md)
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .opacity(animateIn ? 1 : 0)
                .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
        }
    }
}
