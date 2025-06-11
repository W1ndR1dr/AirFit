import SwiftUI

/// # StandardButton
/// 
/// ## Purpose
/// A standardized button component that provides consistent styling across the app.
/// This consolidates various button patterns into a unified implementation.
///
/// ## Usage
/// ```swift
/// StandardButton("Save", style: .primary) {
///     // action
/// }
/// 
/// StandardButton("Cancel", style: .secondary, icon: "xmark") {
///     // action
/// }
/// ```

// MARK: - Button Style
enum ButtonStyleType {
    case primary
    case secondary
    case tertiary
    case destructive
    case custom(background: Color, foreground: Color)
    
    var backgroundColor: Color {
        switch self {
        case .primary: return AppColors.accentColor
        case .secondary: return AppColors.backgroundSecondary
        case .tertiary: return .clear
        case .destructive: return AppColors.errorColor
        case .custom(let bg, _): return bg
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary: return AppColors.textOnAccent
        case .secondary: return AppColors.textPrimary
        case .tertiary: return AppColors.accentColor
        case .destructive: return .white
        case .custom(_, let fg): return fg
        }
    }
    
    var borderColor: Color? {
        switch self {
        case .tertiary: return AppColors.accentColor
        default: return nil
        }
    }
}

// MARK: - Button Size
enum ButtonSize {
    case small
    case medium
    case large
    case custom(height: CGFloat, padding: CGFloat)
    
    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        case .custom(let h, _): return h
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return AppSpacing.small
        case .medium: return AppSpacing.medium
        case .large: return AppSpacing.large
        case .custom(_, let p): return p
        }
    }
    
    var font: Font {
        switch self {
        case .small: return AppFonts.caption
        case .medium: return AppFonts.callout
        case .large: return AppFonts.body
        case .custom: return AppFonts.callout
        }
    }
}

// MARK: - Standard Button
struct StandardButton: View {
    @Environment(\.diContainer) private var diContainer
    
    let title: String
    let icon: String?
    let style: ButtonStyleType
    let size: ButtonSize
    let isFullWidth: Bool
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyleType = .primary,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    /// LocalizedStringKey support for SwiftUI localization
    init(
        _ titleKey: LocalizedStringKey,
        icon: String? = nil,
        style: ButtonStyleType = .primary,
        size: ButtonSize = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        // Extract the key from LocalizedStringKey for NSLocalizedString
        let key = "\(titleKey)"
            .replacingOccurrences(of: "LocalizedStringKey(key: \"", with: "")
            .replacingOccurrences(of: "\", hasFormatting: false)", with: "")
            .replacingOccurrences(of: "\", hasFormatting: true)", with: "")
        
        self.init(
            NSLocalizedString(key, comment: ""),
            icon: icon,
            style: style,
            size: size,
            isFullWidth: isFullWidth,
            isLoading: isLoading,
            isEnabled: isEnabled,
            action: action
        )
    }
    
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: AppSpacing.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(size.font.weight(.medium))
                    }
                    Text(title)
                        .font(size.font)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(style.backgroundColor)
            .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                    .stroke(style.borderColor ?? .clear, lineWidth: 1)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity((isEnabled && !isLoading) ? 1.0 : 0.6)
    }
    
    private func handleTap() {
        // Trigger haptic feedback based on button style
        Task { @MainActor in
            if let hapticService = try? await diContainer.resolve(HapticServiceProtocol.self) {
                switch style {
                case .primary:
                    await hapticService.impact(.medium)
                case .destructive:
                    await hapticService.notification(.warning)
                case .secondary, .tertiary:
                    await hapticService.impact(.light)
                case .custom:
                    await hapticService.impact(.light)
                }
            }
        }
        action()
    }
}

// MARK: - Icon Button
struct IconButton: View {
    @Environment(\.diContainer) private var diContainer
    
    let icon: String
    let style: ButtonStyleType
    let size: ButtonSize
    let action: () -> Void
    
    init(
        icon: String,
        style: ButtonStyleType = .secondary,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Trigger haptic feedback
            Task { @MainActor in
                if let hapticService = try? await diContainer.resolve(HapticServiceProtocol.self) {
                    switch style {
                    case .primary:
                        await hapticService.impact(.medium)
                    case .destructive:
                        await hapticService.notification(.warning)
                    default:
                        await hapticService.impact(.light)
                    }
                }
            }
            action()
        }) {
            Image(systemName: icon)
                .font(size.font.weight(.medium))
                .foregroundColor(style.foregroundColor)
                .frame(width: size.height, height: size.height)
                .background(style.backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(style.borderColor ?? .clear, lineWidth: 1)
                )
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    @Environment(\.diContainer) private var diContainer
    
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Trigger haptic feedback for primary action
            Task { @MainActor in
                if let hapticService = try? await diContainer.resolve(HapticServiceProtocol.self) {
                    await hapticService.impact(.medium)
                }
            }
            action()
        }) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppColors.textOnAccent)
                .frame(width: 56, height: 56)
                .background(AppColors.accentColor)
                .clipShape(Circle())
                .shadow(color: AppColors.accentColor.opacity(0.3), radius: 8, y: 4)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct StandardButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Size variations
            StandardButton("Small", size: .small) { }
            StandardButton("Medium", size: .medium) { }
            StandardButton("Large", size: .large) { }
            
            Divider()
            
            // Style variations
            StandardButton("Primary", style: .primary) { }
            StandardButton("Secondary", style: .secondary) { }
            StandardButton("Tertiary", style: .tertiary) { }
            StandardButton("Destructive", style: .destructive) { }
            
            Divider()
            
            // With icons
            StandardButton("Save", icon: "checkmark", style: .primary) { }
            StandardButton("Cancel", icon: "xmark", style: .secondary) { }
            
            Divider()
            
            // States
            StandardButton("Loading", isLoading: true) { }
            StandardButton("Disabled", isEnabled: false) { }
            
            Divider()
            
            // Full width
            StandardButton("Full Width", isFullWidth: true) { }
            
            // Icon buttons
            HStack {
                IconButton(icon: "plus") { }
                IconButton(icon: "heart.fill", style: .primary) { }
                IconButton(icon: "trash", style: .destructive) { }
            }
            
            Spacer()
            
            // Floating action button
            FloatingActionButton(icon: "plus") { }
        }
        .padding()
        .background(AppColors.backgroundPrimary)
    }
}
#endif