import SwiftUI

/// A text view that animates with a cascading reveal effect
/// Supports multiline text with proper word wrapping
struct CascadeText: View {
    let text: String
    let alignment: TextAlignment
    @State private var isVisible = false
    @State private var weight: CGFloat = 100
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ text: String, alignment: TextAlignment = .center) {
        self.text = text
        self.alignment = alignment
    }

    var body: some View {
        Text(text)
            .multilineTextAlignment(alignment)
            .fontVariableWeight(weight)
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: (isVisible || reduceMotion) ? 0 : 20)
            .blur(radius: (isVisible || reduceMotion) ? 0 : 3)
            .onAppear {
                if reduceMotion {
                    // Simple fade for reduced motion
                    withAnimation(.linear(duration: 0.2)) {
                        isVisible = true
                        weight = 300
                    }
                } else {
                    // Full animation
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        isVisible = true
                    }

                    // Animate weight separately for breathing effect
                    withAnimation(.easeInOut(duration: 1.2)) {
                        weight = 300
                    }
                }
            }
    }
}

/// Letter-by-letter cascade for special emphasis
struct LetterCascadeText: View {
    let text: String
    let alignment: TextAlignment
    @State private var visibleCharacters = 0

    private let words: [[Character]]

    init(_ text: String, alignment: TextAlignment = .center) {
        self.text = text
        self.alignment = alignment
        // Split into words to maintain spacing
        self.words = text.split(separator: " ", omittingEmptySubsequences: false)
            .map { Array($0) }
    }

    var body: some View {
        VStack(alignment: alignment.horizontalAlignment, spacing: 4) {
            ForEach(Array(layoutWords().enumerated()), id: \.offset) { lineIndex, line in
                HStack(spacing: 0) {
                    ForEach(Array(line.enumerated()), id: \.offset) { wordIndex, wordData in
                        HStack(spacing: 0) {
                            ForEach(Array(wordData.word.enumerated()), id: \.offset) { charIndex, char in
                                Text(String(char))
                                    .opacity(characterOpacity(wordData.globalIndex + charIndex))
                                    .offset(y: characterOffset(wordData.globalIndex + charIndex))
                                    .scaleEffect(characterScale(wordData.globalIndex + charIndex))
                            }
                        }

                        if wordIndex < line.count - 1 {
                            Text(" ")
                                .opacity(characterOpacity(wordData.globalIndex))
                        }
                    }
                }
            }
        }
        .onAppear {
            animateText()
        }
    }

    private struct WordData {
        let word: [Character]
        let globalIndex: Int
    }

    private func layoutWords() -> [[WordData]] {
        // Simple layout - in production would measure text
        var lines: [[WordData]] = []
        var currentLine: [WordData] = []
        var globalIndex = 0

        for word in words {
            currentLine.append(WordData(word: word, globalIndex: globalIndex))
            globalIndex += word.count + 1 // +1 for space

            // Simple heuristic - break after 30 chars
            if globalIndex % 30 < word.count {
                lines.append(currentLine)
                currentLine = []
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines.isEmpty ? [[]] : lines
    }

    private func characterOpacity(_ index: Int) -> Double {
        index < visibleCharacters ? 1.0 : 0.0
    }

    private func characterOffset(_ index: Int) -> CGFloat {
        index < visibleCharacters ? 0 : 15
    }

    private func characterScale(_ index: Int) -> CGFloat {
        index < visibleCharacters ? 1.0 : 0.7
    }

    private func animateText() {
        let totalChars = text.filter { $0 != " " }.count

        for i in 0...totalChars {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(Double(i) * 0.03)
            ) {
                visibleCharacters = i
            }
        }
    }
}

// MARK: - Text Alignment Extension

extension TextAlignment {
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - Font Variable Weight Extension

extension View {
    /// Applies variable font weight with proper fallback
    func fontVariableWeight(_ weight: CGFloat) -> some View {
        self.fontWeight(Font.Weight(weight: weight))
    }
}

// MARK: - Font Weight Extension

extension Font.Weight {
    init(weight: CGFloat) {
        switch weight {
        case 0..<150: self = .ultraLight
        case 150..<250: self = .thin
        case 250..<350: self = .light
        case 350..<450: self = .regular
        case 450..<550: self = .medium
        case 550..<650: self = .semibold
        case 650..<750: self = .bold
        case 750..<850: self = .heavy
        default: self = .black
        }
    }
}

// MARK: - Convenience Modifiers

struct CascadeInModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: (isVisible || reduceMotion) ? 0 : 20)
            .onAppear {
                if reduceMotion {
                    // Simple fade for reduced motion
                    withAnimation(.linear(duration: 0.15).delay(min(delay, 0.1))) {
                        isVisible = true
                    }
                } else {
                    // Full cascade animation
                    withAnimation(
                        .spring(response: 0.8, dampingFraction: 0.7)
                            .delay(delay)
                    ) {
                        isVisible = true
                    }
                }
            }
    }
}

extension View {
    /// Applies a simple fade-in cascade animation
    func cascadeIn(delay: Double = 0) -> some View {
        modifier(CascadeInModifier(delay: delay))
    }
}
