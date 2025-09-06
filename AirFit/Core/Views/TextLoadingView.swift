import SwiftUI

/// A conversational text-based loading indicator with animated dots
/// Replaces generic ProgressView() instances with contextual, text-based loading states
public struct TextLoadingView: View {
    let message: String
    let style: Style
    
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    /// Visual styles for different contexts
    public enum Style {
        case standard      // Normal loading text
        case subtle        // Smaller, more subdued
        case prominent     // Larger, more attention-grabbing
    }
    
    public init(message: String, style: Style = .standard) {
        self.message = message
        self.style = style
    }
    
    public var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(message)
                .font(fontForStyle)
                .foregroundStyle(colorForStyle)
            
            // Animated dots
            Text(animatedDots)
                .font(fontForStyle)
                .foregroundStyle(colorForStyle)
                .animation(.smooth(duration: 0.3), value: dotCount)
        }
        .onReceive(timer) { _ in
            withAnimation(SoftMotion.standard) {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
    
    private var animatedDots: String {
        String(repeating: ".", count: max(1, dotCount))
    }
    
    private var fontForStyle: Font {
        switch style {
        case .standard:
            return .system(size: 16, weight: .medium, design: .rounded)
        case .subtle:
            return .system(size: 14, weight: .regular, design: .rounded)
        case .prominent:
            return .system(size: 18, weight: .semibold, design: .rounded)
        }
    }
    
    private var colorForStyle: Color {
        switch style {
        case .standard:
            return .primary.opacity(0.8)
        case .subtle:
            return .secondary
        case .prominent:
            return .primary
        }
    }
}

// MARK: - Convenience Initializers

extension TextLoadingView {
    /// Common loading states with pre-defined messages
    public static func chatThinking() -> TextLoadingView {
        TextLoadingView(message: "Coach is thinking", style: .standard)
    }
    
    public static func loadingNutrition() -> TextLoadingView {
        TextLoadingView(message: "Loading nutrition data", style: .standard)
    }
    
    public static func analyzingWorkout() -> TextLoadingView {
        TextLoadingView(message: "Analyzing your workout", style: .standard)
    }
    
    public static func checkingSettings() -> TextLoadingView {
        TextLoadingView(message: "Checking settings", style: .subtle)
    }
    
    public static func connectingToCoach() -> TextLoadingView {
        TextLoadingView(message: "Connecting to coach", style: .standard)
    }
    
    public static func loadingProfile() -> TextLoadingView {
        TextLoadingView(message: "Loading your profile", style: .standard)
    }
    
    public static func preparingData() -> TextLoadingView {
        TextLoadingView(message: "Preparing your data", style: .standard)
    }
}

// MARK: - Preview

#if DEBUG
struct TextLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: AppSpacing.large) {
            TextLoadingView.chatThinking()
            TextLoadingView.loadingNutrition()
            TextLoadingView(message: "Processing voice input", style: .subtle)
            TextLoadingView(message: "Generating insights", style: .prominent)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif