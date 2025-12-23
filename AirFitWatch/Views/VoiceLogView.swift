import SwiftUI

/// Voice logging view for quick food entry on Watch.
/// Uses native watchOS dictation through TextField.
struct VoiceLogView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss

    @State private var transcript = ""
    @State private var isSending = false
    @State private var showConfirmation = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Log Food")
                .font(.headline)

            // Instructions
            Text("Tap to dictate or type")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Text input with dictation support
            TextField("30g protein shake...", text: $transcript)
                .focused($isTextFieldFocused)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color(white: 0.2))
                .cornerRadius(8)
                .submitLabel(.send)
                .onSubmit {
                    if !transcript.isEmpty {
                        sendLog()
                    }
                }

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                // Dictate button
                Button(action: { isTextFieldFocused = true }) {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Send button
                if !transcript.isEmpty {
                    Button(action: sendLog) {
                        if isSending {
                            ProgressView()
                                .frame(width: 44, height: 44)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                }
            }
        }
        .padding()
        .alert("Logged!", isPresented: $showConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text(connectivityManager.lastVoiceLogResult ?? "Food logged successfully")
        }
        .onAppear {
            // Auto-focus to trigger dictation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Send Log

    private func sendLog() {
        guard !transcript.isEmpty else { return }

        isSending = true
        connectivityManager.sendFoodLog(transcript)

        // Wait briefly for response then show confirmation
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                isSending = false
                showConfirmation = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VoiceLogView()
        .environmentObject(WatchConnectivityManager.shared)
}
