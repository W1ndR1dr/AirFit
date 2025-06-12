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
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    private var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Use our MicRippleView instead of VoiceVisualizer
            MicRippleView(isRecording: isRecording, size: 120)
                .onTapGesture {
                    toggleRecording()
                }
            
            // Recording status with animations
            VStack(spacing: AppSpacing.xs) {
                if isRecording {
                    CascadeText("Listening...")
                        .font(.system(size: 22, weight: .light, design: .rounded))
                    
                    Text(formattedDuration)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                } else if !transcription.isEmpty {
                    Text("Tap to re-record or continue")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.secondary)
                } else {
                    Text("Tap to start speaking")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.primary)
                }
            }
            
            // Transcription preview with glass morphism
            if showTranscription && !transcription.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("You said:")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.secondary)
                        
                        Text(transcription)
                            .font(.system(size: 16, weight: .regular))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Submit button when transcription is available
            if !transcription.isEmpty && !isRecording {
                Button {
                    HapticService.impact(.light)
                    submitRecording()
                } label: {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: gradientManager.active.colors(for: colorScheme).first?.opacity(0.3) ?? .clear, 
                                radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .transition(.scale.combined(with: .opacity))
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
        
        HapticService.impact(.light)
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
                withAnimation(MotionToken.standardSpring) {
                    showTranscription = true
                }
                HapticService.notification(.success)
            }
        }
    }
    
    private func submitRecording() {
        guard !transcription.isEmpty,
              let audioData = voiceRecorder.lastRecordingData else { return }
        
        HapticService.impact(.medium)
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