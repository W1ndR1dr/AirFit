import Foundation
import SwiftUI

// MARK: - PersonalityTrait for Settings Display
struct PersonalityTrait: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let dimension: PersonalityDimension
    let value: Double

    init(dimension: PersonalityDimension, value: Double) {
        self.dimension = dimension
        self.value = value

        switch dimension {
        case .authorityPreference:
            self.name = "Authority Style"
            self.description = value > 0.5 ? "Responds well to structure" : "Prefers autonomy"
            self.icon = "person.badge.shield.checkmark"
        case .socialOrientation:
            self.name = "Social Style"
            self.description = value > 0.5 ? "Community-focused" : "Individual-focused"
            self.icon = "person.3"
        case .structureNeed:
            self.name = "Structure Preference"
            self.description = value > 0.5 ? "Likes detailed plans" : "Flexible approach"
            self.icon = "list.bullet.rectangle"
        case .intensityPreference:
            self.name = "Intensity Level"
            self.description = value > 0.5 ? "High-energy approach" : "Calm and measured"
            self.icon = "flame"
        case .dataOrientation:
            self.name = "Data Preference"
            self.description = value > 0.5 ? "Analytics-driven" : "Intuition-based"
            self.icon = "chart.line.uptrend.xyaxis"
        case .emotionalSupport:
            self.name = "Support Style"
            self.description = value > 0.5 ? "Emotionally supportive" : "Results-focused"
            self.icon = "heart.circle"
        }
    }
}

// MARK: - Extensions for Settings Display
extension CoachPersona {
    /// Extract dominant traits for settings display
    var dominantTraits: [PersonalityTrait] {
        let insights = profile

        return insights.traits
            .sorted { $0.value > $1.value }
            .prefix(4)
            .map { PersonalityTrait(dimension: $0.key, value: $0.value) }
    }

    /// Generate a unique initials for avatar display
    var initials: String {
        let words = identity.name.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "AI"
    }

    /// Generate gradient colors based on personality
    var gradientColors: [Color] {
        // Use personality traits to determine color scheme
        let baseHue = (profile.traits[.intensityPreference] ?? 0.5) * 360
        let saturation = (profile.traits[.emotionalSupport] ?? 0.5) * 0.5 + 0.5

        return [
            Color(hue: baseHue / 360, saturation: saturation, brightness: 0.9),
            Color(hue: (baseHue + 30) / 360, saturation: saturation * 0.8, brightness: 0.7)
        ]
    }

    /// Calculate uniqueness score (0-1)
    var uniquenessScore: Double {
        // Calculate based on variance from average values
        let insights = profile

        let traitVariances = insights.traits.values.map { abs($0 - 0.5) }
        let avgVariance = traitVariances.reduce(0, +) / Double(traitVariances.count)

        // More variance = more unique
        return min(avgVariance * 2, 1.0)
    }

    /// Calculate difference from another persona
    func calculateDifference(from other: CoachPersona) -> Double {
        let myTraits = profile.traits
        let otherTraits = other.profile.traits

        var totalDiff = 0.0
        for (dimension, myValue) in myTraits {
            if let otherValue = otherTraits[dimension] {
                totalDiff += abs(myValue - otherValue)
            }
        }

        return totalDiff / Double(myTraits.count)
    }
}

// MARK: - Communication Style Extensions
extension VoiceCharacteristics {
    var tone: CommunicationTone {
        switch energy {
        case .high:
            return .energetic
        case .moderate:
            return warmth == .warm ? .casual : .balanced
        case .calm:
            return vocabulary == .advanced ? .formal : .balanced
        }
    }

    var energyLevel: EnergyLevel {
        switch energy {
        case .high: return .high
        case .moderate: return .medium
        case .calm: return .low
        }
    }

    var detailLevel: DetailLevel {
        switch vocabulary {
        case .advanced: return .comprehensive
        case .moderate: return .moderate
        case .simple: return .minimal
        }
    }

    var humorStyle: HumorStyle {
        // Infer from warmth and energy
        switch (warmth, energy) {
        case (.warm, .high): return .playful
        case (.warm, _): return .light
        case (.friendly, _): return .occasional
        default: return .minimal
        }
    }
}

// MARK: - Settings-Specific Enums
enum EnergyLevel: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var displayName: String { rawValue }
}

enum HumorStyle: String, CaseIterable {
    case playful = "Playful"
    case light = "Light"
    case occasional = "Occasional"
    case minimal = "Minimal"

    var displayName: String { rawValue }
}

// MARK: - Simplified Communication Style for Settings
struct SimplifiedCommunicationStyle {
    let tone: CommunicationTone
    let energyLevel: EnergyLevel
    let detailLevel: DetailLevel
    let humorStyle: HumorStyle
}

extension CoachPersona {
    var communicationStyle: SimplifiedCommunicationStyle {
        SimplifiedCommunicationStyle(
            tone: communication.tone,
            energyLevel: communication.energyLevel,
            detailLevel: communication.detailLevel,
            humorStyle: communication.humorStyle
        )
    }

    var coachingPhilosophy: CoachingPhilosophyDisplay {
        CoachingPhilosophyDisplay(
            core: philosophy.approach,
            principles: philosophy.principles
        )
    }
}

struct CoachingPhilosophyDisplay {
    let core: String
    let principles: [String]
}
