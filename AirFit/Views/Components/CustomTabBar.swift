import SwiftUI

// MARK: - Custom Floating Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onTap: (Int) -> Void
    @Namespace private var tabAnimation

    private let tabs: [(icon: String, label: String)] = [
        ("square.grid.2x2", "Dashboard"),
        ("fork.knife", "Nutrition"),
        ("bubble.left.and.bubble.right.fill", "Coach"),
        ("sparkles", "Insights"),
        ("person.circle", "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                TabBarButton(
                    icon: tab.icon,
                    label: tab.label,
                    isSelected: selectedTab == index,
                    namespace: tabAnimation
                ) {
                    onTap(index)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Tab Bar Button

private struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)

                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Theme.accent : Theme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Theme.accent.opacity(0.12))
                        .matchedGeometryEffect(id: "selectedTab", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.storytelling, value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Preview

#Preview("Tab Bar - Light") {
    ZStack {
        Theme.background
            .ignoresSafeArea()

        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(2)) { _ in }
        }
    }
}

#Preview("Tab Bar - Dark") {
    ZStack {
        Theme.background
            .ignoresSafeArea()

        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(0)) { _ in }
        }
    }
    .preferredColorScheme(.dark)
}
