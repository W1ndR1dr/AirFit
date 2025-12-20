import SwiftUI
import SwiftData

/// Transparency view for the LLM-synthesized coaching persona.
///
/// Follows Anthropic's philosophy: users should have full visibility
/// and edit control over how the AI understands them.
///
/// Users can:
/// - **See** the current coaching persona (the prose the AI uses)
/// - **Edit** it directly if desired
/// - **Regenerate** it with one tap
/// - **View** when it was last updated
struct CoachingPersonaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var persona: String = ""
    @State private var isEditing = false
    @State private var isRegenerating = false
    @State private var lastGenerated: Date?
    @State private var showingRegenerateConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                // Persona display/editor
                personaSection

                // Actions
                actionSection

                // Info footer
                infoSection

                Spacer(minLength: 100)
            }
            .padding(24)
        }
        .background(Theme.background)
        .navigationTitle("Coaching Persona")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadPersona)
        .confirmationDialog(
            "Regenerate Persona?",
            isPresented: $showingRegenerateConfirm,
            titleVisibility: .visible
        ) {
            Button("Regenerate", role: .destructive) {
                regeneratePersona()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace your current coaching persona with a newly synthesized one based on your profile, preferences, and conversation history.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Coaching Approach")
                .font(.headlineLarge)
                .foregroundStyle(Theme.textPrimary)

            Text("This is how your AI coach understands your preferences and how to work with you. It's synthesized from your profile, calibration choices, and conversation history.")
                .font(.bodyMedium)
                .foregroundStyle(Theme.textSecondary)

            if let date = lastGenerated {
                Text("Last updated: \(date.formatted(.relative(presentation: .named)))")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }

    // MARK: - Persona Section

    private var personaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Persona")
                    .font(.bodyLarge.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isEditing {
                            savePersona()
                        }
                        isEditing.toggle()
                    }
                } label: {
                    Text(isEditing ? "Save" : "Edit")
                        .font(.bodyMedium.weight(.medium))
                        .foregroundStyle(Theme.accent)
                }
            }

            if isEditing {
                // Editable text view
                TextEditor(text: $persona)
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Theme.surface)
                    .frame(minHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.accent.opacity(0.5), lineWidth: 1)
                    )
            } else {
                // Display view
                if persona.isEmpty {
                    emptyPersonaView
                } else {
                    Text(persona)
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var emptyPersonaView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(Theme.textMuted)

            Text("No persona generated yet")
                .font(.bodyLarge.weight(.medium))
                .foregroundStyle(Theme.textSecondary)

            Text("Complete onboarding and calibration to generate your personalized coaching persona.")
                .font(.bodyMedium)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 12) {
            // Regenerate button
            Button {
                showingRegenerateConfirm = true
            } label: {
                HStack {
                    if isRegenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }

                    Text(isRegenerating ? "Regenerating..." : "Regenerate Persona")
                        .font(.bodyLarge.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isRegenerating ? Theme.accent.opacity(0.5) : Theme.accent)
                )
            }
            .disabled(isRegenerating || isEditing)

            // Cancel edit button (when editing)
            if isEditing {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        loadPersona() // Reload original
                        isEditing = false
                    }
                } label: {
                    Text("Cancel Edit")
                        .font(.bodyLarge.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.textPrimary.opacity(0.05))
                        )
                }
            }
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How it works")
                .font(.labelLarge.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "person.fill", text: "Your profile data (goals, preferences, context)")
                infoRow(icon: "slider.horizontal.3", text: "Calibration choices (tone, roast tolerance, advice style)")
                infoRow(icon: "brain.head.profile", text: "Conversation memories (inside jokes, callbacks)")
                infoRow(icon: "chart.line.uptrend.xyaxis", text: "Observed patterns (what works for you)")
            }

            Text("These signals are synthesized by AI into natural prose that guides how your coach interacts with you. The persona refreshes weekly and after significant changes.")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)
                .padding(.top, 4)
        }
        .padding(16)
        .background(Theme.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
                .frame(width: 20)

            Text(text)
                .font(.labelMedium)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Actions

    private func loadPersona() {
        let profile = LocalProfile.getOrCreate(in: modelContext)
        persona = profile.coachingPersona ?? ""
        lastGenerated = profile.coachingPersonaGeneratedAt
    }

    private func savePersona() {
        let profile = LocalProfile.getOrCreate(in: modelContext)
        profile.coachingPersona = persona
        profile.lastLocalUpdate = Date()
        try? modelContext.save()
    }

    private func regeneratePersona() {
        isRegenerating = true

        Task {
            let success = await PersonalitySynthesisService.shared.synthesizeAndSave(modelContext: modelContext)

            await MainActor.run {
                isRegenerating = false
                if success {
                    loadPersona() // Reload the new persona
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CoachingPersonaView()
    }
    .modelContainer(for: [LocalProfile.self, LocalMemory.self])
}
