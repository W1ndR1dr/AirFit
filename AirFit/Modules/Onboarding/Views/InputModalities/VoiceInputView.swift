import SwiftUI
import AVFoundation

struct VoiceInputView: View {
    let maxDuration: TimeInterval
    let onSubmit: (String, Data) -> Void
    
    @StateObject private var voiceRecorder = VoiceRecorder()
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var transcription = ""
    @State private var showTranscription = false
    @State private var timer: Timer?
    
    private var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Voice visualizer
            VoiceVisualizer(
                isRecording: isRecording,
                audioLevel: voiceRecorder.audioLevel
            )
            .frame(height: 120)
            
            // Recording status
            VStack(spacing: 8) {
                if isRecording {
                    Text("Listening...")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formattedDuration)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(.secondary)
                } else if !transcription.isEmpty {
                    Text("Tap to re-record or continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Tap to start speaking")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            // Transcription preview
            if showTranscription && !transcription.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You said:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(transcription)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Control buttons
            HStack(spacing: 20) {
                // Record button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.accentColor)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isRecording)
                
                // Submit button (when transcription available)
                if !transcription.isEmpty && !isRecording {
                    Button(action: submitRecording) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Privacy note
            Text("Your voice is processed locally for privacy")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .onDisappear {
            stopRecording()
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        voiceRecorder.startRecording()
        isRecording = true
        recordingDuration = 0
        showTranscription = false
        
        // Start duration timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                recordingDuration += 0.1
                
                // Auto-stop at max duration
                if recordingDuration >= maxDuration {
                    stopRecording()
                }
            }
        }
                 // TODO: Add haptic feedback via DI when needed
    }
    
    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        isRecording = false
        
        Task {
            if let audioData = await voiceRecorder.stopRecording() {
                // In real app, transcribe audio here
                // For now, use placeholder
                transcription = "This is where your transcribed speech would appear"
                showTranscription = true
                                 // TODO: Add haptic feedback via DI when needed
            }
        }
    }
    
    private func submitRecording() {
        guard !transcription.isEmpty,
              let audioData = voiceRecorder.lastRecordingData else { return }
                 // TODO: Add haptic feedback via DI when needed
        onSubmit(transcription, audioData)
    }
}

// MARK: - Voice Recorder
@MainActor
class VoiceRecorder: ObservableObject {
    @Published var audioLevel: Float = 0
    @Published var isRecording = false
    
    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var recordingURL: URL?
    
    var lastRecordingData: Data?
    
    func startRecording() {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)
        
        // Setup recorder
        recordingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            
            // Start monitoring audio levels
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.audioRecorder?.updateMeters()
                    let level = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                    self.audioLevel = max(0, 1 + level / 160)
                }
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() async -> Data? {
        levelTimer?.invalidate()
        audioRecorder?.stop()
        isRecording = false
        audioLevel = 0
        
        // Read recorded data
        if let url = recordingURL {
            lastRecordingData = try? Data(contentsOf: url)
            try? FileManager.default.removeItem(at: url)
            return lastRecordingData
        }
        
        return nil
    }
}