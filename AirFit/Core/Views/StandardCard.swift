import SwiftUI

/// # StandardCard
/// 
/// ## Purpose
/// A standardized card component that provides consistent styling across the app.
/// This is a temporary implementation for Phase 3.1 that will be replaced
/// by GlassCard in Phase 3.3.
///
/// ## Usage
/// ```swift
/// Card {
///     // Your content here
/// }
/// ```
///
/// ## Customization
/// ```swift
/// Card(padding: .large, showShadow: false) {
///     // Custom styled content
/// }
/// ```

struct StandardCard<Content: View>: View {
    let content: Content
    let padding: CardPadding
    let showShadow: Bool
    
    /// Standard card with default styling
    init(
        padding: CardPadding = .standard,
        showShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.showShadow = showShadow
    }
    
    var body: some View {
        content
            .padding(padding.value)
            .background(AppColors.cardBackground)
            .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            .shadow(
                color: showShadow ? AppColors.shadowColor : .clear,
                radius: showShadow ? 4 : 0,
                x: 0,
                y: showShadow ? 2 : 0
            )
    }
}

// MARK: - Padding Options

enum CardPadding {
    case none
    case small
    case standard
    case large
    
    var value: CGFloat {
        switch self {
        case .none: return 0
        case .small: return AppSpacing.small
        case .standard: return AppSpacing.medium
        case .large: return AppSpacing.large
        }
    }
}

// MARK: - Convenience Modifiers

extension View {
    /// Apply standard card styling to any view
    func cardStyle(padding: CardPadding = .standard, showShadow: Bool = true) -> some View {
        StandardCard(padding: padding, showShadow: showShadow) {
            self
        }
    }
}

// MARK: - Tappable Card

struct TappableCard<Content: View>: View {
    let content: Content
    let padding: CardPadding
    let showShadow: Bool
    let action: () -> Void
    
    init(
        padding: CardPadding = .standard,
        showShadow: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.showShadow = showShadow
        self.action = action
    }
    
    var body: some View {
        StandardCard(padding: padding, showShadow: showShadow) {
            content
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// MARK: - Preview

#if DEBUG
struct StandardCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Standard card
            StandardCard {
                Text("Standard Card")
                    .font(AppFonts.headline)
            }
            
            // Large padding card
            StandardCard(padding: .large) {
                VStack(alignment: .leading) {
                    Text("Large Padding")
                        .font(AppFonts.headline)
                    Text("More room to breathe")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            // No shadow card
            StandardCard(showShadow: false) {
                Text("No Shadow")
            }
            
            // Tappable card
            TappableCard {
                print("Tapped!")
            } content: {
                Label("Tap Me", systemImage: "hand.tap")
            }
            
            // Using modifier
            Text("Card Modifier")
                .cardStyle()
        }
        .padding()
        .background(AppColors.backgroundPrimary)
    }
}
#endif