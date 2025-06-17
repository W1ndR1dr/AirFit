import SwiftUI

/// Animated waveform visualization for voice input with gradient support
public struct VoiceWaveformView: View {
    // MARK: - Properties
    
    /// Audio levels to display (0.0 to 1.0)
    public let levels: [Float]
    
    /// Configuration options
    public var config: Configuration
    
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme)
    private var colorScheme
    @State private var animateIn = false
    
    // MARK: - Configuration
    
    public struct Configuration {
        /// Width of each waveform bar
        public var barWidth: CGFloat = 2.5
        
        /// Spacing between bars
        public var barSpacing: CGFloat = 1.5
        
        /// Minimum bar height
        public var minimumHeight: CGFloat = 4
        
        /// Maximum height multiplier (relative to view height)
        public var heightMultiplier: CGFloat = 0.8
        
        /// Whether to use gradient with opacity variations
        public var useGradientOpacity: Bool = true
        
        /// Whether to animate entrance
        public var animateEntrance: Bool = true
        
        /// Bar shape style
        public var barShape: BarShape = .capsule
        
        /// Animation style for level changes
        public var levelAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)
        
        /// Animation style for entrance
        public var entranceAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.8)
        
        public enum BarShape {
            case capsule
            case roundedRectangle(cornerRadius: CGFloat)
        }
        
        public init() {}
        
        /// Preset for chat/message composer usage
        public static var chat: Configuration {
            Configuration()
        }
        
        /// Preset for food tracking usage
        public static var foodTracking: Configuration {
            var config = Configuration()
            config.barWidth = 3
            config.barSpacing = 2
            config.useGradientOpacity = false
            config.animateEntrance = false
            config.barShape = .roundedRectangle(cornerRadius: 2)
            config.levelAnimation = .easeInOut(duration: 0.1)
            return config
        }
    }
    
    // MARK: - Initialization
    
    public init(levels: [Float], config: Configuration = .chat) {
        self.levels = levels
        self.config = config
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: config.barSpacing) {
                ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                    barView(for: level, at: index, in: geometry.size)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            if config.animateEntrance {
                animateIn = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    @ViewBuilder
    private func barView(for level: Float, at index: Int, in size: CGSize) -> some View {
        let height = max(config.minimumHeight, CGFloat(level) * size.height * config.heightMultiplier)
        
        Group {
            switch config.barShape {
            case .capsule:
                Capsule()
                    .fill(barFill)
                    .frame(width: config.barWidth, height: height)
            case .roundedRectangle(let cornerRadius):
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(barFill)
                    .frame(width: config.barWidth, height: height)
            }
        }
        .scaleEffect(y: config.animateEntrance ? (animateIn ? 1 : 0.3) : 1, anchor: .center)
        .animation(
            config.levelAnimation.delay(Double(index) * 0.02),
            value: level
        )
        .animation(
            config.animateEntrance ? config.entranceAnimation.delay(Double(index) * 0.01) : nil,
            value: animateIn
        )
    }
    
    private var barFill: some ShapeStyle {
        if config.useGradientOpacity {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        gradientManager.active.colors(for: colorScheme)[0].opacity(0.8),
                        gradientManager.active.colors(for: colorScheme)[1].opacity(0.6)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        } else {
            return AnyShapeStyle(gradientManager.currentGradient(for: colorScheme))
        }
    }
}

// MARK: - Preview

#if DEBUG
struct VoiceWaveformView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Chat style
            VoiceWaveformView(
                levels: [0.2, 0.5, 0.8, 0.3, 0.6, 0.4, 0.7, 0.5, 0.3, 0.6],
                config: .chat
            )
            .frame(height: 40)
            
            // Food tracking style
            VoiceWaveformView(
                levels: [0.2, 0.5, 0.8, 0.3, 0.6, 0.4, 0.7, 0.5, 0.3, 0.6],
                config: .foodTracking
            )
            .frame(height: 40)
        }
        .padding()
        .environmentObject(GradientManager())
    }
}
#endif
