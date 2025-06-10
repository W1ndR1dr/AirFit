import SwiftUI

struct TextInputView: View {
    let minLength: Int
    let maxLength: Int
    let placeholder: String
    let onSubmit: (String) -> Void
    
    @State private var text = ""
    @State private var showError = false
    @FocusState private var isFocused: Bool
    
    private var isValid: Bool {
        text.count >= minLength && text.count <= maxLength
    }
    
    private var characterCount: Int {
        text.count
    }
    
    private var remainingCharacters: Int {
        maxLength - text.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Input field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .lineLimit(1...5)
                        .focused($isFocused)
                        .onChange(of: text) { _, newValue in
                            if newValue.count > maxLength {
                                text = String(newValue.prefix(maxLength))
                            }
                            showError = false
                        }
                        .onSubmit {
                            submitResponse()
                        }
                    
                    if !text.isEmpty {
                        Button(action: { text = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            showError ? Color.red : (isFocused ? Color.accentColor : Color.clear),
                            lineWidth: 2
                        )
                )
                
                // Character count
                HStack {
                    if showError {
                        Text("Minimum \(minLength) characters required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text("\(characterCount)/\(maxLength)")
                        .font(.caption)
                        .foregroundColor(remainingCharacters < 20 ? .orange : .secondary)
                }
                .padding(.horizontal, 4)
            }
            
            // Smart suggestions
            if isFocused && text.isEmpty {
                SmartSuggestions(
                    context: placeholder,
                    onSelect: { suggestion in
                        text = suggestion
                        submitResponse()
                    }
                )
            }
            
            // Submit button
            Button(action: submitResponse) {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValid ? Color.accentColor : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isValid)
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
    
    private func submitResponse() {
        guard isValid else {
            showError = true
            // TODO: Add haptic feedback via DI when needed
            return
        }
                 // TODO: Add haptic feedback via DI when needed
        onSubmit(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: - Smart Suggestions Component
struct SmartSuggestions: View {
    let context: String
    let onSelect: (String) -> Void
    
    private var suggestions: [String] {
        // Context-aware suggestions based on the question
        switch context.lowercased() {
        case let ctx where ctx.contains("goal"):
            return [
                "Get stronger and build muscle",
                "Lose weight and feel healthier",
                "Improve my endurance for sports",
                "Maintain fitness and stay active"
            ]
        case let ctx where ctx.contains("experience"):
            return [
                "I'm new to fitness",
                "I work out occasionally",
                "I exercise regularly",
                "I'm an experienced athlete"
            ]
        case let ctx where ctx.contains("motivation"):
            return [
                "Looking and feeling my best",
                "Improving my health markers",
                "Setting a good example",
                "Achieving personal records"
            ]
        default:
            return []
        }
    }
    
    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Suggestions:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: { onSelect(suggestion) }) {
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }
}