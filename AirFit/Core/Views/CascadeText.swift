import SwiftUI

/// A text view that animates each letter with a cascading reveal effect
/// Letters animate in with increasing weight for a breathing, wave-like entrance
struct CascadeText: View {
    let text: String
    @State private var visibleCharacters = 0
    @State private var characterWeights: [CGFloat] = []
    
    private let characters: [Character]
    
    init(_ text: String) {
        self.text = text
        self.characters = Array(text)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .fontWeight(fontWeight(for: index))
                    .opacity(opacity(for: index))
                    .offset(y: offset(for: index))
                    .scaleEffect(scale(for: index))
                    .animation(
                        Animation.interpolatingSpring(stiffness: 80, damping: 12)
                            .speed(0.8)
                            .delay(MotionToken.cascadeDelay(for: index, total: characters.count)),
                        value: visibleCharacters
                    )
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func fontWeight(for index: Int) -> Font.Weight? {
        guard index < characterWeights.count else { return .ultraLight }
        let weight = characterWeights[index]
        
        // Map CGFloat weight to Font.Weight
        switch weight {
        case 0..<350: return .ultraLight
        case 350..<400: return .light
        case 400..<500: return .regular
        case 500..<600: return .medium
        case 600..<700: return .semibold
        case 700..<800: return .bold
        default: return .heavy
        }
    }
    
    private func opacity(for index: Int) -> Double {
        index < visibleCharacters ? 1.0 : 0.0
    }
    
    private func offset(for index: Int) -> CGFloat {
        index < visibleCharacters ? 0 : MotionToken.cascadeOffsetY
    }
    
    private func scale(for index: Int) -> CGFloat {
        index < visibleCharacters ? 1.0 : 0.8
    }
    
    private func startAnimation() {
        // Initialize weights
        characterWeights = Array(repeating: MotionToken.cascadeWeightFrom, count: characters.count)
        
        // Animate each character
        for index in 0..<characters.count {
            let delay = MotionToken.cascadeDelay(for: index, total: characters.count)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(
                    .interpolatingSpring(stiffness: 80, damping: 12)
                    .speed(0.8)
                ) {
                    visibleCharacters = index + 1
                    if index < characterWeights.count {
                        characterWeights[index] = MotionToken.cascadeWeightTo
                    }
                }
            }
        }
    }
}

// MARK: - Cascade Modifier

/// A modifier that applies cascade animation to existing text
struct CascadeModifier: ViewModifier {
    @State private var isVisible = false
    @State private var weight: CGFloat = MotionToken.cascadeWeightFrom
    
    func body(content: Content) -> some View {
        content
            .fontVariableWeight(weight)
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : MotionToken.cascadeOffsetY)
            .onAppear {
                withAnimation(.easeOut(duration: MotionToken.cascadeDuration)) {
                    isVisible = true
                    weight = MotionToken.cascadeWeightTo
                }
            }
    }
}

// MARK: - Font Variable Weight Extension

extension View {
    /// Applies variable font weight if available
    func fontVariableWeight(_ weight: CGFloat) -> some View {
        if #available(iOS 16.0, *) {
            return self.fontWeight(Font.Weight(rawValue: weight))
        } else {
            // Fallback for older iOS versions
            let mappedWeight: Font.Weight = {
                switch weight {
                case 0..<350: return .ultraLight
                case 350..<400: return .light
                case 400..<500: return .regular
                case 500..<600: return .medium
                case 600..<700: return .semibold
                case 700..<800: return .bold
                default: return .heavy
                }
            }()
            return self.fontWeight(mappedWeight)
        }
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Applies cascade animation to any text view
    func cascadeAnimation() -> some View {
        modifier(CascadeModifier())
    }
}

// MARK: - Font Weight Extension

extension Font.Weight {
    init(rawValue: CGFloat) {
        switch rawValue {
        case 0..<200: self = .ultraLight
        case 200..<300: self = .thin
        case 300..<400: self = .light
        case 400..<500: self = .regular
        case 500..<600: self = .medium
        case 600..<700: self = .semibold
        case 700..<800: self = .bold
        case 800..<900: self = .heavy
        default: self = .black
        }
    }
}