import SwiftUI

// MARK: - Section Header
public struct SectionHeader: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?

    init(title: String, icon: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            if let action = action {
                Button(action: action) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Empty State View
public struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(
        icon: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }

    public var body: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.quaternary)

            VStack(spacing: AppSpacing.small) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Card View
public struct Card<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .padding(AppSpacing.medium)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.medium))
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Loading Overlay Modifier
public struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?

    public func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)

            if isLoading {
                VStack(spacing: AppSpacing.medium) {
                    ProgressView()
                        .scaleEffect(1.5)

                    if let message = message {
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(AppSpacing.xLarge)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.medium))
                .shadow(radius: 10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}
