import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// Screen 5: Comment input with dictation
struct CommentInputView: View {
    @Bindable var coordinator: WorkoutLoggingCoordinator
    @State private var showingDictation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(coordinator.exerciseName)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("Add Comment")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Optional")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.top)
            
            Spacer()
            
            // Comment content or prompt
            VStack(spacing: 16) {
                if coordinator.setComment.isEmpty {
                    // Mic button
                    Button {
                        showingDictation = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Text("Tap to add comment")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                } else {
                    // Show comment
                    VStack(spacing: 12) {
                        Text(coordinator.setComment)
                            .font(.system(size: 16))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        HStack(spacing: 16) {
                            Button {
                                coordinator.setComment = ""
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 14))
                                    Text("Clear")
                                        .font(.system(size: 14))
                                }
                                .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                showingDictation = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "mic.circle")
                                        .font(.system(size: 14))
                                    Text("Edit")
                                        .font(.system(size: 14))
                                }
                                .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Common quick phrases
                if coordinator.setComment.isEmpty {
                    VStack(spacing: 8) {
                        Text("Common notes:")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickPhrases, id: \.self) { phrase in
                                    Button {
                                        coordinator.setComment = phrase
                                        #if os(watchOS)
                                        WKInterfaceDevice.current().play(.click)
                                        #endif
                                    } label: {
                                        Text(phrase)
                                            .font(.system(size: 12))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Navigation buttons
            VStack(spacing: 12) {
                // Continue/Skip button
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        coordinator.navigateForward()
                    }
                } label: {
                    Text(coordinator.setComment.isEmpty ? "Skip" : "Continue")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(coordinator.setComment.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                // Back button
                HStack {
                    Button {
                        withAnimation(.smooth(duration: 0.2)) {
                            coordinator.navigateBackward()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingDictation) {
            DictationView(
                title: "Set Comment",
                initialText: coordinator.setComment,
                placeholder: "Describe this set...",
                onComplete: { comment in
                    coordinator.setComment = comment
                }
            )
        }
    }
    
    private var quickPhrases: [String] {
        // Context-aware phrases based on exercise
        var phrases = ["Form breakdown", "Felt strong", "Grip failed", "Good set"]
        
        let exerciseName = coordinator.exerciseName.lowercased()
        
        // Add exercise-specific phrases
        if exerciseName.contains("squat") || exerciseName.contains("leg") {
            phrases.append("Depth good")
            phrases.append("Knee discomfort")
        } else if exerciseName.contains("bench") || exerciseName.contains("press") {
            phrases.append("Shoulder tight")
            phrases.append("Good lockout")
        } else if exerciseName.contains("deadlift") || exerciseName.contains("rdl") {
            phrases.append("Lower back pump")
            phrases.append("Grip limiting")
        } else if exerciseName.contains("curl") {
            phrases.append("Good squeeze")
            phrases.append("Elbow pain")
        } else if exerciseName.contains("calf") {
            phrases.append("Cramping")
            phrases.append("Burn limited")
        }
        
        return Array(phrases.prefix(5))
    }
}