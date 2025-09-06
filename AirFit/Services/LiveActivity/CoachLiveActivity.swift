//
//  CoachLiveActivity.swift
//  AirFit
//
//  Created on 2025-09-06 for iPhone 16 Pro Dynamic Island integration
//  AI Coach Live Activity with iOS 26 Liquid Glass effects
//

import ActivityKit
import SwiftUI

// MARK: - AI Coach Live Activity Widget

struct CoachLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CoachActivityAttributes.self) { context in
            // Lock screen view with iOS 26 Liquid Glass effects
            CoachLockScreenView(context: context)
                .glassEffect(.regular)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view when user long-presses the Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Session type indicator
                        HStack(spacing: 6) {
                            Image(systemName: getSessionIcon(context.attributes.sessionType))
                                .foregroundStyle(getSessionColor(context.attributes.sessionType))
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text(context.attributes.sessionType.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        
                        // Urgency indicator
                        if context.state.urgency != .normal {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(getUrgencyColor(context.state.urgency))
                                    .frame(width: 6, height: 6)
                                Text(context.state.urgency.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(getUrgencyColor(context.state.urgency))
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        // Message count
                        HStack(spacing: 4) {
                            Text("\(context.state.messageCount)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("msgs")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Response status
                        if context.state.responseWaiting {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Thinking...")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else if context.state.sessionActive {
                            Text("Active")
                                .font(.caption2)
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 6) {
                        // AI Coach indicator
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                                .font(.system(size: 14))
                                .symbolEffect(.pulse, isActive: context.state.responseWaiting)
                            
                            Text("AI Coach")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                        
                        // Last message preview (truncated)
                        Text(context.state.lastMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 120)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        // Session duration
                        let duration = Date().timeIntervalSince(context.attributes.startTime)
                        let minutes = Int(duration / 60)
                        Text("\(minutes)m session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        // Quick action buttons
                        HStack(spacing: 12) {
                            if context.state.responseWaiting {
                                Button(intent: StopThinkingIntent()) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.plain)
                                .glassEffect(.thin)
                                .frame(width: 32, height: 32)
                                .background(.red.opacity(0.2), in: Circle())
                            }
                            
                            Button(intent: ReplyToCoachIntent()) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.thin)
                            .frame(width: 32, height: 32)
                            .background(.regularMaterial, in: Circle())
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                // Compact left side - Session type icon
                Image(systemName: getSessionIcon(context.attributes.sessionType))
                    .foregroundStyle(getSessionColor(context.attributes.sessionType))
                    .font(.system(size: 14, weight: .semibold))
                    .symbolEffect(.bounce, value: context.state.messageCount)
            } compactTrailing: {
                // Compact right side - Message count and status
                VStack(spacing: 1) {
                    if context.state.responseWaiting {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Text("\(context.state.messageCount)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        if context.state.urgency != .normal {
                            Circle()
                                .fill(getUrgencyColor(context.state.urgency))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            } minimal: {
                // Minimal view - AI sparkles icon
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                    .font(.system(size: 14, weight: .medium))
                    .symbolEffect(.pulse, isActive: context.state.responseWaiting)
            }
        }
    }
}

// MARK: - Lock Screen View

struct CoachLockScreenView: View {
    let context: ActivityViewContext<CoachActivityAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with session info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                            .font(.system(size: 18))
                        
                        Text("AI Coach Session")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(context.attributes.sessionType.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let duration = Date().timeIntervalSince(context.attributes.startTime)
                    let minutes = Int(duration / 60)
                    Text("\(minutes) min")
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                    
                    if context.state.responseWaiting {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Thinking")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("\(context.state.messageCount) messages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Last message content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Latest Message")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if context.state.urgency != .normal {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(getUrgencyColor(context.state.urgency))
                                .frame(width: 8, height: 8)
                            Text(context.state.urgency.rawValue)
                                .font(.caption2)
                                .foregroundStyle(getUrgencyColor(context.state.urgency))
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Text(context.state.lastMessage)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Action indicators
            if context.state.sessionActive {
                HStack(spacing: 16) {
                    if context.state.responseWaiting {
                        Label("AI is generating response...", systemImage: "brain")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    } else {
                        Label("Tap to continue conversation", systemImage: "bubble.left.and.bubble.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Helper Functions

private func getSessionIcon(_ sessionType: CoachSessionType) -> String {
    switch sessionType {
    case .workout:
        return "figure.strengthtraining.traditional"
    case .nutrition:
        return "leaf.fill"
    case .recovery:
        return "bed.double.fill"
    case .motivation:
        return "flame.fill"
    }
}

private func getSessionColor(_ sessionType: CoachSessionType) -> Color {
    switch sessionType {
    case .workout:
        return .blue
    case .nutrition:
        return .green
    case .recovery:
        return .purple
    case .motivation:
        return .orange
    }
}

private func getUrgencyColor(_ urgency: CoachUrgency) -> Color {
    switch urgency {
    case .low:
        return .gray
    case .normal:
        return .primary
    case .high:
        return .orange
    case .urgent:
        return .red
    }
}

// MARK: - App Intents

struct ReplyToCoachIntent: AppIntent {
    static var title: LocalizedStringResource = "Reply to Coach"
    
    func perform() async throws -> some IntentResult {
        // Send notification to open chat
        NotificationCenter.default.post(name: .openAIChat, object: nil)
        return .result()
    }
}

struct StopThinkingIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop AI Response"
    
    func perform() async throws -> some IntentResult {
        // Send notification to stop AI response
        NotificationCenter.default.post(name: .stopAIResponse, object: nil)
        return .result()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let openAIChat = Notification.Name("openAIChat")
    static let stopAIResponse = Notification.Name("stopAIResponse")
}