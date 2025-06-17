import SwiftUI

// MARK: - Minimal Message Bubble
struct MinimalMessageBubble: View {
    let message: ChatMessage
    let isStreaming: Bool
    let onAction: (MessageAction) -> Void
    
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.roleEnum == .user {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: message.roleEnum == .user ? .trailing : .leading, spacing: 4) {
                // Clean bubble without cards or glass effects
                messageBubble
                    .scaleEffect(animateIn ? 1.0 : 0.95)
                    .opacity(animateIn ? 1.0 : 0.0)
                
                // Minimal metadata
                if message.roleEnum == .assistant && hasSource {
                    sourceLink
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3).delay(0.1), value: animateIn)
                }
            }
            
            if message.roleEnum == .assistant {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateIn = true
            }
        }
    }
    
    private var messageBubble: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text content with streaming support
            if isStreaming {
                StreamingText(
                    text: message.content,
                    style: message.roleEnum == .user ? .user : .assistant
                )
            } else {
                Text(message.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(message.roleEnum == .user ? .white : .primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(bubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contextMenu {
            Button(action: { onAction(.copy) }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            if message.roleEnum == .assistant {
                Button(action: { onAction(.regenerate) }) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
            }
        }
    }
    
    @ViewBuilder
    private var bubbleBackground: some View {
        if message.roleEnum == .user {
            // User messages: subtle gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.6, blue: 0.9),
                    Color(red: 0.3, green: 0.7, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Assistant messages: light gray
            Color(UIColor.systemGray6)
        }
    }
    
    private var sourceLink: some View {
        Button(action: {
            HapticService.selection()
            onAction(.showDetails)
        }) {
            HStack(spacing: 4) {
                Text("Source")
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
    
    private var hasSource: Bool {
        // Check if message has source metadata or function calls
        message.functionCallName != nil
    }
}

// MARK: - Streaming Text Component
private struct StreamingText: View {
    let text: String
    let style: StreamingStyle
    
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    enum StreamingStyle {
        case user, assistant
        
        var font: Font {
            .system(size: 16, weight: .regular)
        }
        
        var color: Color {
            switch self {
            case .user: return .white
            case .assistant: return .primary
            }
        }
        
        var speed: Int {
            switch self {
            case .user: return 10 // Faster for user
            case .assistant: return 25 // Natural for assistant
            }
        }
    }
    
    var body: some View {
        Text(displayedText)
            .font(style.font)
            .foregroundStyle(style.color)
            .multilineTextAlignment(.leading)
            .task {
                await streamText()
            }
    }
    
    private func streamText() async {
        displayedText = ""
        currentIndex = 0
        
        let characters = Array(text)
        for (index, character) in characters.enumerated() {
            displayedText.append(character)
            currentIndex = index
            
            // Variable delay for more natural streaming
            let delay = character == " " ? style.speed / 2 : style.speed
            try? await Task.sleep(for: .milliseconds(delay))
        }
    }
}