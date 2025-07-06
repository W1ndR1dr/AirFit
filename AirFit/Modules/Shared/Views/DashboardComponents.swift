import SwiftUI

// MARK: - Dashboard Protocol

/// Protocol for consistent dashboard implementation
protocol DashboardViewProtocol: View {
    associatedtype ViewModel: DashboardViewModelProtocol
    var viewModel: ViewModel? { get }
    var user: User { get }
}

/// Protocol for dashboard ViewModels
protocol DashboardViewModelProtocol: Observable, ErrorHandling {
    var isLoading: Bool { get }
    func loadData() async
}

// MARK: - Shared Loading View

/// Consistent loading view for all dashboards
struct DashboardLoadingView: View {
    let message: String
    @State private var animateGradient = false
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Animated gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: animateGradient ? .topLeading : .bottomTrailing,
                        endPoint: animateGradient ? .bottomTrailing : .topLeading
                    )
                )
                .frame(width: 60, height: 60)
                .blur(radius: 8)
                .scaleEffect(animateGradient ? 1.1 : 0.9)
                .opacity(animateGradient ? 0.8 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: animateGradient
                )

            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Shared Error View

/// Consistent error view for all dashboards
struct DashboardErrorView: View {
    let error: AppError
    let onRetry: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    @State private var animate = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // Error icon with subtle animation
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animate ? 1.0 : 0.9)
                .animation(
                    .spring(duration: 0.6).repeatForever(autoreverses: true),
                    value: animate
                )

            VStack(spacing: AppSpacing.sm) {
                Text("Something went wrong")
                    .font(.system(size: 20, weight: .semibold))

                Text(error.localizedDescription)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            animate = true
            HapticService.notification(.error)
        }
    }
}

// MARK: - Timeframe Picker

/// Reusable timeframe picker for dashboards
struct DashboardTimeframePicker<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    @Binding var selection: T
    let onChange: ((T) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    init(selection: Binding<T>, onChange: ((T) -> Void)? = nil) {
        self._selection = selection
        self.onChange = onChange
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(T.allCases), id: \.self) { timeframe in
                timeframeButton(for: timeframe)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func timeframeButton(for timeframe: T) -> some View {
        let isSelected = selection == timeframe

        Button {
            withAnimation(.spring(duration: 0.3)) {
                selection = timeframe
                HapticService.impact(.light)
                onChange?(timeframe)
            }
        } label: {
            Text(timeframe.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State View

/// Consistent empty state for dashboards
struct DashboardEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var animate = false
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Icon with gradient and animation
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.8) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animate ? 1.0 : 0.9)
                .opacity(animate ? 1.0 : 0.6)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: animate
                )

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))

                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Section Header

/// Consistent section header for dashboards
struct DashboardSectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
    }
}

// MARK: - Progress Indicator

/// Animated progress indicator for dashboards
struct DashboardProgressIndicator: View {
    let progress: Double
    let label: String?

    @State private var animateIn = false
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateIn ? geometry.size.width * progress : 0, height: 8)
                        .animation(.spring(duration: 0.8), value: animateIn)
                }
            }
            .frame(height: 8)

            if let label = label {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
    }
}

// MARK: - Content Wrapper

/// Wrapper for dashboard content with consistent animations
struct DashboardContentView<Content: View>: View {
    let delay: Double
    let content: Content

    @State private var animateIn = false

    init(delay: Double = 0, @ViewBuilder content: () -> Content) {
        self.delay = delay
        self.content = content()
    }

    var body: some View {
        content
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            .animation(MotionToken.standardSpring.delay(delay), value: animateIn)
            .onAppear {
                animateIn = true
            }
    }
}
