import SwiftUI

struct ModelRecommendationView: View {
    let provider: AIProvider
    @Binding var selectedModel: String

    private var recommendedModels: [(model: String, reason: String, isPremium: Bool)] {
        switch provider {
        case .anthropic:
            return [
                ("claude-3-opus-20240229", "Best for persona generation - highest quality, most creative", true),
                ("claude-3-5-sonnet-20241022", "Great balance of quality and speed", false),
                ("claude-3-haiku-20240307", "Fast and economical for daily use", false)
            ]
        case .openAI:
            return [
                ("gpt-4o", "Most capable - excellent for complex personas", true),
                ("gpt-4o-mini", "Good balance - recommended for most users", false),
                ("gpt-3.5-turbo", "Fast and economical", false)
            ]
        case .gemini:
            return [
                ("gemini-2.0-flash-thinking-exp", "Latest model with advanced reasoning", true),
                ("gemini-1.5-pro-002", "Best for persona generation", true),
                ("gemini-1.5-flash-002", "Fast and efficient for daily use", false)
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Model Selection")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary.opacity(0.6))
            }

            GlassCard {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(recommendedModels, id: \.model) { item in
                        ModelOption(
                            model: item.model,
                            reason: item.reason,
                            isPremium: item.isPremium,
                            isSelected: selectedModel == item.model,
                            onSelect: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedModel = item.model
                                    HapticService.impact(.light)
                                }
                            }
                        )

                        if item.model != recommendedModels.last?.model {
                            Divider()
                                .padding(.vertical, 2)
                        }
                    }
                }
            }

            // Recommendation note
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)

                Text("We recommend premium models for initial persona generation")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.sm)
        }
    }
}

private struct ModelOption: View {
    let model: String
    let reason: String
    let isPremium: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    private var displayName: String {
        // Convert model ID to readable name
        model
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "claude 3 ", with: "Claude ")
            .replacingOccurrences(of: "gpt ", with: "GPT-")
            .replacingOccurrences(of: "gemini ", with: "Gemini ")
            .split(separator: " ")
            .map { word in
                if word.count <= 3 {
                    return word.uppercased()
                } else {
                    return word.capitalized
                }
            }
            .joined(separator: " ")
            .replacingOccurrences(of: " 20240229", with: "")
            .replacingOccurrences(of: " 20241022", with: "")
            .replacingOccurrences(of: " 20240307", with: "")
            .replacingOccurrences(of: " 002", with: "")
            .replacingOccurrences(of: " Exp", with: " (Preview)")
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppSpacing.sm) {
                // Selection indicator
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(displayName)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? .primary : .secondary)

                        if isPremium {
                            Label("Premium", systemImage: "crown.fill")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }

                    Text(reason)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.8))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.vertical, AppSpacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        ModelRecommendationView(
            provider: .anthropic,
            selectedModel: .constant("claude-3-opus-20240229")
        )

        ModelRecommendationView(
            provider: .openAI,
            selectedModel: .constant("gpt-4o")
        )
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}
