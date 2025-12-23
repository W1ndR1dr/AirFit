import SwiftUI
import Speech

/// Voice logging view for quick food entry on Watch.
/// Uses on-device speech recognition for transcription.
struct VoiceLogView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss

    @State private var isListening = false
    @State private var transcript = ""
    @State private var audioLevel: Float = 0
    @State private var errorMessage: String?
    @State private var isSending = false
    @State private var showConfirmation = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Log Food")
                .font(.headline)

            // Waveform visualization
            HStack(spacing: 2) {
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isListening ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 4, height: waveformHeight(for: index))
                        .animation(.easeInOut(duration: 0.1), value: audioLevel)
                }
            }
            .frame(height: 30)

            // Transcript display
            if !transcript.isEmpty {
                Text(transcript)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(maxHeight: 60)
            } else if isListening {
                Text("Listening...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Tap mic to start")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
            }

            Spacer()

            // Microphone button
            Button(action: toggleListening) {
                ZStack {
                    Circle()
                        .fill(isListening ? Color.red : Color.blue)
                        .frame(width: 60, height: 60)

                    if isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: isListening ? "stop.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isSending)

            // Send button (when transcript exists)
            if !transcript.isEmpty && !isListening {
                Button(action: sendLog) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Log")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isSending)
            }
        }
        .padding()
        .alert("Logged!", isPresented: $showConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text(connectivityManager.lastVoiceLogResult ?? "Food logged successfully")
        }
        .onAppear {
            requestSpeechAuthorization()
        }
        .onDisappear {
            stopListening()
        }
    }

    // MARK: - Waveform

    private func waveformHeight(for index: Int) -> CGFloat {
        guard isListening else { return 8 }
        let baseHeight: CGFloat = 8
        let maxAdditional: CGFloat = 22
        let variation = sin(Double(index) * 0.8 + Double(audioLevel) * 10) * 0.5 + 0.5
        return baseHeight + CGFloat(audioLevel) * maxAdditional * CGFloat(variation)
    }

    // MARK: - Speech Recognition

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                switch status {
                case .authorized:
                    errorMessage = nil
                case .denied:
                    errorMessage = "Speech recognition denied"
                case .restricted:
                    errorMessage = "Speech recognition restricted"
                case .notDetermined:
                    errorMessage = "Speech recognition not authorized"
                @unknown default:
                    errorMessage = "Unknown authorization status"
                }
            }
        }
    }

    private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition unavailable"
            return
        }

        // Reset state
        transcript = ""
        errorMessage = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error"
            return
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            errorMessage = "Could not create request"
            return
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true  // On-device for privacy

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self.stopListening()
                }
            }
        }

        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)

            // Calculate audio level for visualization
            let channelData = buffer.floatChannelData?[0]
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength {
                sum += abs(channelData?[i] ?? 0)
            }
            let average = sum / Float(frameLength)

            Task { @MainActor in
                self.audioLevel = min(1.0, average * 10)
            }
        }

        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            errorMessage = "Audio engine error"
        }
    }

    private func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        audioLevel = 0
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
