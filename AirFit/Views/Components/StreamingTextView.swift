import SwiftUI

/// Animated text view that reveals content character-by-character.
/// Used for streaming AI responses to create a premium "typing" effect.
///
/// ## Usage
/// ```swift
/// StreamingTextView(
///     fullText: streamingContent,
///     isComplete: !isStreaming,
///     charactersPerSecond: 40
/// )
/// ```
struct StreamingTextView: View {
    /// The full text to display (updates as streaming chunks arrive)
    let fullText: String

    /// Whether streaming is complete (shows all text immediately when true)
    let isComplete: Bool

    /// How fast to reveal characters (default: 40 chars/second)
    var charactersPerSecond: Double = 40

    /// Internal state for animation
    @State private var revealedCount: Int = 0
    @State private var cursorVisible: Bool = true

    /// The portion of text currently visible
    private var visibleText: String {
        if isComplete {
            return fullText
        }
        let endIndex = min(revealedCount, fullText.count)
        return String(fullText.prefix(endIndex))
    }

    /// Whether we're still revealing characters
    private var isRevealing: Bool {
        !isComplete && revealedCount < fullText.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Render the visible text with markdown support
            if !visibleText.isEmpty {
                MarkdownStreamText(visibleText)
            }

            // Typing cursor (only while streaming)
            if isRevealing || (!isComplete && revealedCount >= fullText.count) {
                typingCursor
                    .transition(.opacity)
            }
        }
        .onAppear {
            startRevealAnimation()
        }
        .onChange(of: fullText) { _, newText in
            // When new text arrives, continue revealing from current position
            // Don't reset - just let the animation catch up
        }
        .onChange(of: isComplete) { _, complete in
            if complete {
                // Immediately show all text when complete
                revealedCount = fullText.count
            }
        }
    }

    // MARK: - Typing Cursor

    private var typingCursor: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Theme.accent)
            .frame(width: 2, height: 18)
            .opacity(cursorVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: cursorVisible)
            .onAppear {
                cursorVisible = true
            }
    }

    // MARK: - Animation

    private func startRevealAnimation() {
        guard !isComplete else {
            revealedCount = fullText.count
            return
        }

        // Calculate interval between character reveals
        let interval = 1.0 / charactersPerSecond

        // Use a timer to reveal characters
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if isComplete || revealedCount >= fullText.count {
                timer.invalidate()
                return
            }

            // Reveal next character(s) - sometimes reveal 2-3 for natural feel
            let charsToReveal = Int.random(in: 1...2)
            revealedCount = min(revealedCount + charsToReveal, fullText.count)
        }
    }
}

// MARK: - Markdown Stream Text

/// Simplified markdown renderer for streaming text.
/// Renders the visible portion with basic formatting.
private struct MarkdownStreamText: View {
    let content: String

    init(_ content: String) {
        self.content = content
    }

    var body: some View {
        // Use AttributedString for inline markdown (bold, italic)
        // This handles partial text gracefully
        Text(attributedContent)
            .font(.bodyMedium)
            .foregroundStyle(Theme.textPrimary)
            .lineSpacing(4)
    }

    private var attributedContent: AttributedString {
        // Try to parse as markdown, fall back to plain text
        if let attributed = try? AttributedString(
            markdown: content,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return attributed
        }
        return AttributedString(content)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @State private var isComplete = false

        let fullText = """
        Here's what I see in your meal:

        **Grilled Chicken Salad**
        - Grilled chicken breast (~150g)
        - Mixed greens
        - Cherry tomatoes
        - Avocado slices

        **Nutrition Estimate:**
        - Calories: ~450 kcal
        - Protein: 35g
        - Carbs: 15g
        - Fat: 28g

        This looks like a solid high-protein meal! Great choice for your goals.
        """

        var body: some View {
            VStack(spacing: 20) {
                ScrollView {
                    StreamingTextView(
                        fullText: text,
                        isComplete: isComplete,
                        charactersPerSecond: 50
                    )
                    .padding()
                }
                .frame(maxHeight: 400)

                HStack {
                    Button("Start Stream") {
                        text = ""
                        isComplete = false
                        simulateStream()
                    }

                    Button("Complete") {
                        text = fullText
                        isComplete = true
                    }
                }
            }
            .padding()
            .background(Theme.background)
        }

        func simulateStream() {
            // Simulate streaming chunks
            var index = 0
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                if index >= fullText.count {
                    timer.invalidate()
                    isComplete = true
                    return
                }

                let chunkSize = Int.random(in: 5...15)
                let endIndex = min(index + chunkSize, fullText.count)
                text = String(fullText.prefix(endIndex))
                index = endIndex
            }
        }
    }

    return PreviewWrapper()
}
