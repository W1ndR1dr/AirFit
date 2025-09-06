import SwiftUI

// iOS 26 Gradient Text Component
struct GradientText: View {
    let text: String
    let style: GradientStyle
    
    enum GradientStyle {
        case primary    // Blue to purple
        case accent     // Orange to pink
        case subtle     // Gray gradient
        case success    // Green gradient
        case premium    // Gold gradient
        
        var colors: [Color] {
            switch self {
            case .primary: return [.blue, .purple]
            case .accent: return [.orange, .pink]
            case .subtle: return [.gray, .gray.opacity(0.7)]
            case .success: return [.green, .mint]
            case .premium: return [.yellow, .orange]
            }
        }
    }
    
    var body: some View {
        Text(text)
            .foregroundStyle(
                LinearGradient(
                    colors: style.colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Convenience Initializers
extension GradientText {
    init(_ text: String, style: GradientStyle = .primary) {
        self.text = text
        self.style = style
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        GradientText("Primary Gradient", style: .primary)
            .font(.title)
        
        GradientText("Accent Gradient", style: .accent)
            .font(.headline)
        
        GradientText("Subtle Gradient", style: .subtle)
            .font(.body)
        
        GradientText("Success Gradient", style: .success)
            .font(.callout)
        
        GradientText("Premium Gradient", style: .premium)
            .font(.caption)
    }
    .padding()
}