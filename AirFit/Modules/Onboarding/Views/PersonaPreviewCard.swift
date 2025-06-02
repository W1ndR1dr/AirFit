import SwiftUI

struct PersonaPreviewCard: View {
    let preview: PersonaPreview
    @State private var showContent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            if let name = preview.name, let archetype = preview.archetype {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(archetype)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(.spring(response: 0.5).delay(0.1), value: showContent)
            }
            
            // Traits
            if !preview.traits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Traits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 8) {
                        ForEach(preview.traits, id: \.self) { trait in
                            TraitChip(trait: trait)
                                .opacity(showContent ? 1 : 0)
                                .scaleEffect(showContent ? 1 : 0.8)
                                .animation(
                                    .spring(response: 0.4)
                                        .delay(Double(preview.traits.firstIndex(of: trait) ?? 0) * 0.1 + 0.2),
                                    value: showContent
                                )
                        }
                    }
                }
            }
            
            // Preview message
            if let message = preview.previewMessage {
                Text(message)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.5).delay(0.3), value: showContent)
            }
            
            // Visual element
            if preview.stage == .buildingPersonality || preview.stage == .finalizing {
                PersonaVisualization()
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)
                    .animation(.spring(response: 0.6).delay(0.4), value: showContent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
        .onChange(of: preview.stage) { _, _ in
            showContent = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showContent = true
                }
            }
        }
    }
}

struct TraitChip: View {
    let trait: String
    
    var body: some View {
        Text(trait)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.1))
            )
    }
}

struct PersonaVisualization: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.3),
                                Color.accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 80)
                    .rotationEffect(.degrees(rotation + Double(index * 10)))
                    .scaleEffect(scale)
                    .animation(
                        .easeInOut(duration: 3)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: rotation
                    )
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            rotation = -5
            scale = 0.95
        }
    }
}