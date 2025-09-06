import SwiftUI

/// Screen 1: Exercise name input with dictation
struct ExerciseInputView: View {
    @Bindable var coordinator: WorkoutLoggingCoordinator
    @State private var showingDictation = false
    @State private var showingEquipmentDictation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                if let progress = coordinator.workoutManager?.currentSetProgress {
                    Text("Set \(progress.current) of \(progress.total)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                Text("Exercise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // Exercise name
            VStack(spacing: 8) {
                Text(coordinator.exerciseName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)
                
                Button {
                    showingDictation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 20))
                        Text("Change Name")
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            
            // Equipment note if exists
            if !coordinator.exerciseComment.isEmpty {
                Text(coordinator.exerciseComment)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(.horizontal)
            }
            
            // Add equipment note button
            Button {
                showingEquipmentDictation = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.system(size: 14))
                    Text("Add Note")
                        .font(.system(size: 14))
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Continue button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    coordinator.navigateForward()
                }
            } label: {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                }
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .navigationBarHidden(true)
        .sheet(isPresented: $showingDictation) {
            DictationView(
                title: "Exercise Name",
                initialText: coordinator.exerciseName,
                onComplete: { newName in
                    coordinator.exerciseName = newName
                    // Note: Cannot update exercise name in workout data because ExerciseBuilderData.name is immutable
                    AppLogger.info("Updated exercise name locally: \(newName)", category: .ui)
                }
            )
        }
        .sheet(isPresented: $showingEquipmentDictation) {
            DictationView(
                title: "Equipment/Setup Note",
                initialText: coordinator.exerciseComment,
                onComplete: { note in
                    coordinator.exerciseComment = note
                }
            )
        }
    }
}