import SwiftUI

struct VoiceMicButton: View {
    @Binding var text: String
    @State private var speechRecognizer: SpeechRecognizer?
    @State private var isAuthorizing = false

    var body: some View {
        Button {
            Task { await handleTap() }
        } label: {
            Image(systemName: iconName)
                .font(.system(size: 32))
                .foregroundColor(iconColor)
                .symbolEffect(.pulse, isActive: speechRecognizer?.isRecording == true)
        }
        .disabled(isAuthorizing)
        .onChange(of: speechRecognizer?.transcript) { _, newValue in
            if let newValue, speechRecognizer?.isRecording == true {
                text = newValue
            }
        }
    }

    private var iconName: String {
        if speechRecognizer?.isRecording == true {
            return "stop.circle.fill"
        }
        return "mic.circle.fill"
    }

    private var iconColor: Color {
        if isAuthorizing {
            return .gray
        }
        if speechRecognizer?.isRecording == true {
            return .red
        }
        if speechRecognizer?.isAuthorized == true {
            return .blue
        }
        // Not yet initialized - show blue to indicate it's tappable
        return .blue
    }

    private func handleTap() async {
        // Lazy init - only create recognizer on first tap
        if speechRecognizer == nil {
            isAuthorizing = true
            let recognizer = SpeechRecognizer()
            _ = await recognizer.requestAuthorization()
            speechRecognizer = recognizer
            isAuthorizing = false
        }

        guard let recognizer = speechRecognizer else { return }

        if recognizer.isRecording {
            text = recognizer.stopRecording()
        } else if recognizer.isAuthorized {
            recognizer.startRecording()
        }
    }
}
