import SwiftUI

/// View that displays voice model download progress
struct VoiceInputDownloadView: View {
    let state: VoiceInputState
    let onCancel: (() -> Void)?
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            switch state {
            case .idle:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text("Initializing voice input...")
                    .font(.headline)
                
            case .downloadingModel(let progress, let modelName):
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    
                    Text("Downloading Voice Model")
                        .font(.headline)
                    
                    Text(modelName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(maxWidth: 250)
                    
                    HStack {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if progress < 0.3 {
                            Text("This may take a few minutes...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if progress < 0.7 {
                            Text("Almost there...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Finishing up...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: 250)
                    
                    if let onCancel {
                        Button(action: {
                            HapticService.impact(.light)
                            onCancel()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.xs)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.primary.opacity(0.05),
                                            Color.primary.opacity(0.02)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                
            case .preparingModel:
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Text("Preparing voice model...")
                        .font(.headline)
                    
                    Text("This only happens once")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
            case .error(let error):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)
                    
                    Text("Download Failed")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                    
                    if let onCancel {
                        Button(action: {
                            HapticService.impact(.light)
                            onCancel()
                        }) {
                            Text("Dismiss")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.xs)
                                .background(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.2), radius: 6, y: 2)
                        }
                    }
                }
                
            default:
                EmptyView()
            }
        }
        .padding(32)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .frame(maxWidth: 400)
    }
}

/// Overlay modifier for showing voice download progress
struct VoiceInputDownloadOverlay: ViewModifier {
    @Binding var voiceInputState: VoiceInputState
    let onCancel: (() -> Void)?
    
    private var shouldShow: Bool {
        switch voiceInputState {
        case .idle, .downloadingModel, .preparingModel, .error:
            return true
        case .ready, .recording, .transcribing:
            return false
        }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if shouldShow {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .transition(.opacity)
                        
                        VoiceInputDownloadView(
                            state: voiceInputState,
                            onCancel: onCancel
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: shouldShow)
            )
    }
}

extension View {
    /// Shows voice input download progress overlay when needed
    func voiceInputDownloadOverlay(
        state: Binding<VoiceInputState>,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        modifier(VoiceInputDownloadOverlay(
            voiceInputState: state,
            onCancel: onCancel
        ))
    }
}

// MARK: - Preview
#Preview("Download Progress") {
    VStack {
        Color.clear
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(uiColor: .systemGroupedBackground))
    .voiceInputDownloadOverlay(
        state: .constant(.downloadingModel(progress: 0.45, modelName: "Base (74 MB)"))
    )
}

#Preview("States") {
    VStack(spacing: 20) {
        VoiceInputDownloadView(
            state: .idle,
            onCancel: nil
        )
        
        VoiceInputDownloadView(
            state: .downloadingModel(progress: 0.65, modelName: "Base (74 MB)"),
            onCancel: {}
        )
        
        VoiceInputDownloadView(
            state: .preparingModel,
            onCancel: nil
        )
        
        VoiceInputDownloadView(
            state: .error(.modelDownloadFailed("Network connection lost")),
            onCancel: {}
        )
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}