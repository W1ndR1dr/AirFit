import SwiftUI

/// Native dictation view for watchOS using text input
struct DictationView: View {
    let title: String
    let initialText: String
    let placeholder: String
    let onComplete: (String) -> Void
    
    @State private var text: String
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(title: String, initialText: String = "", placeholder: String = "Tap to speak...", onComplete: @escaping (String) -> Void) {
        self.title = title
        self.initialText = initialText
        self.placeholder = placeholder
        self.onComplete = onComplete
        self._text = State(initialValue: initialText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top)
                
                if !initialText.isEmpty {
                    Text("Current: \(initialText)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Text input area
            VStack(spacing: 16) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .onAppear {
                        isFocused = true
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                
                if !text.isEmpty && text != initialText {
                    // Preview of changes
                    VStack(spacing: 4) {
                        Text("New value:")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(text)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 8) {
                if !text.isEmpty && text != initialText {
                    Button {
                        onComplete(text)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationBarHidden(true)
    }
}