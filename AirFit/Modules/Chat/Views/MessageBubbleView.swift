import SwiftUI
import Charts

struct MessageBubbleView: View {
    let message: ChatMessage
    let isStreaming: Bool
    let onAction: (MessageAction) -> Void
    
    @State private var showActions = false
    @State private var isExpanded = false
    @State private var animateIn = false
    @State private var selectedReaction: String?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.small) {
            if message.roleEnum == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.roleEnum == .user ? .trailing : .leading, spacing: AppSpacing.xSmall) {
                // Message bubble
                bubble
                    .scaleEffect(animateIn ? 1.0 : 0.8)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateIn)
                
                // Timestamp and status
                messageFooter
            }
            
            if message.roleEnum == .assistant {
                Spacer(minLength: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
    }
    
    private var bubble: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            // Attachments
            if !message.attachments.isEmpty {
                attachmentsView
            }
            
            // Message content
            if !message.content.isEmpty {
                MessageContent(
                    text: message.content,
                    isStreaming: isStreaming,
                    role: message.roleEnum
                )
            }
            
            // Rich content (charts, buttons, etc)
            richContent
            
            // Interactive elements
            if message.roleEnum == .assistant {
                interactiveElements
            }
        }
        .padding()
        .background(bubbleBackground)
        .clipShape(ChatBubbleShape(role: message.roleEnum))
        .shadow(
            color: .black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )
        .contextMenu {
            messageActions
        }
        .onTapGesture {
            if hasExpandableContent {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
        }
    }
    
    @ViewBuilder
    private var bubbleBackground: some View {
        if message.roleEnum == .user {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            AppColors.cardBackground
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    @ViewBuilder
    private var attachmentsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(message.attachments) { attachment in
                    AttachmentThumbnail(
                        attachment: attachment,
                        isExpanded: isExpanded
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    @ViewBuilder
    private var richContent: some View {
        if message.roleEnum == .assistant {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                // Check for function call data instead of metadata
                if let functionName = message.functionCallName {
                    // Handle different types of rich content based on function calls
                    switch functionName {
                    case let name where name.contains("chart"):
                        ChartView(
                            data: [ChatChartDataPoint(label: "Sample", value: 100)],
                            isExpanded: isExpanded
                        )
                    case let name where name.contains("navigation"):
                        NavigationLinkCard(
                            title: "View Workout",
                            subtitle: "Tap to see details",
                            destination: "WorkoutDetail",
                            icon: "figure.run"
                        )
                    case let name where name.contains("reminder"):
                        ReminderCard(
                            time: "8:00 AM",
                            title: "Workout Reminder",
                            isExpanded: isExpanded
                        )
                    default:
                        EmptyView()
                    }
                }
                
                // Progress indicators for function calls
                if message.functionCallName != nil {
                    ProgressCard(
                        progress: 0.75,
                        isExpanded: isExpanded
                    )
                }
                
                // Quick actions for assistant messages
                if message.roleEnum == .assistant {
                    QuickActionsView(
                        actions: [
                            ChatQuickAction(id: "schedule_workout", title: "Schedule Workout"),
                            ChatQuickAction(id: "view_progress", title: "View Progress"),
                            ChatQuickAction(id: "set_reminder", title: "Set Reminder")
                        ],
                        onAction: { actionId in
                            handleQuickAction(actionId)
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var interactiveElements: some View {
        if message.roleEnum == .assistant && !isStreaming {
            HStack(spacing: AppSpacing.small) {
                // Reaction buttons
                HStack(spacing: 4) {
                    ReactionButton(
                        emoji: "👍",
                        isSelected: selectedReaction == "👍",
                        onTap: { toggleReaction("👍") }
                    )
                    
                    ReactionButton(
                        emoji: "👎",
                        isSelected: selectedReaction == "👎",
                        onTap: { toggleReaction("👎") }
                    )
                    
                    ReactionButton(
                        emoji: "❤️",
                        isSelected: selectedReaction == "❤️",
                        onTap: { toggleReaction("❤️") }
                    )
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    Button(action: { onAction(.copy) }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { onAction(.regenerate) }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, AppSpacing.xSmall)
            .opacity(0.7)
        }
    }
    
    private var messageFooter: some View {
        HStack(spacing: AppSpacing.xSmall) {
            if message.roleEnum == .user && isStreaming {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.8)
            }
            
            // Timestamp
            Text(formatTimestamp(message.timestamp))
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            // Message status indicators
            if message.roleEnum == .user {
                messageStatusIcon
            }
            
            // Token count for assistant messages
            if message.roleEnum == .assistant,
               let tokenCount = message.tokenCount {
                Text("• \(tokenCount) tokens")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    @ViewBuilder
    private var messageStatusIcon: some View {
        if isStreaming {
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if message.errorMessage != nil {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption2)
                .foregroundStyle(.red)
        } else {
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.green)
        }
    }
    
    @ViewBuilder
    private var messageActions: some View {
        Button(action: { onAction(.copy) }) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        if message.roleEnum == .assistant {
            Button(action: { onAction(.regenerate) }) {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
        }
        
        Button(action: { onAction(.showDetails) }) {
            Label("Details", systemImage: "info.circle")
        }
        
        if hasExpandableContent {
            Button(action: { 
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                Label(isExpanded ? "Collapse" : "Expand", 
                      systemImage: isExpanded ? "chevron.up" : "chevron.down")
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: { onAction(.delete) }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Helper Properties
    
    private var hasExpandableContent: Bool {
        // Check if message has function calls or attachments that can be expanded
        return message.functionCallName != nil || !message.attachments.isEmpty
    }
    
    // MARK: - Helper Methods
    
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return date.formatted(.dateTime.hour().minute())
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday " + date.formatted(.dateTime.hour().minute())
        } else {
            return date.formatted(.dateTime.month().day().hour().minute())
        }
    }
    
    private func toggleReaction(_ emoji: String) {
        // Simple reaction toggle - in a real app this would persist to the message
        if selectedReaction == emoji {
            selectedReaction = nil
        } else {
            selectedReaction = emoji
        }
        
        // Haptic feedback
        HapticManager.impact(.light)
    }
    
    private func handleQuickAction(_ actionId: String) {
        // Handle quick action taps
        switch actionId {
        case "schedule_workout":
            onAction(.scheduleWorkout)
        case "view_progress":
            onAction(.viewProgress)
        case "set_reminder":
            onAction(.setReminder)
        default:
            break
        }
    }
}

// MARK: - Supporting Views

struct ChatBubbleShape: Shape {
    let role: ChatMessage.Role
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 8
        
        var path = Path()
        
        if role == .user {
            // User bubble (right side with tail)
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius - tailSize, y: 0))
            path.addArc(
                center: CGPoint(x: rect.width - radius - tailSize, y: radius),
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            
            // Tail
            path.addLine(to: CGPoint(x: rect.width - tailSize, y: rect.height - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height),
                control: CGPoint(x: rect.width - tailSize, y: rect.height)
            )
            path.addLine(to: CGPoint(x: rect.width - tailSize - radius, y: rect.height))
            
            path.addArc(
                center: CGPoint(x: rect.width - tailSize - radius, y: rect.height - radius),
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            
            path.addLine(to: CGPoint(x: radius, y: rect.height - radius))
            path.addArc(
                center: CGPoint(x: radius, y: rect.height - radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
            
            path.addLine(to: CGPoint(x: rect.width - radius - tailSize, y: radius))
            path.addArc(
                center: CGPoint(x: radius, y: radius),
                radius: radius,
                startAngle: .degrees(270),
                endAngle: .degrees(180),
                clockwise: true
            )
            
        } else {
            // Assistant bubble (left side with tail)
            path.move(to: CGPoint(x: radius + tailSize, y: 0))
            path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
            path.addArc(
                center: CGPoint(x: rect.width - radius, y: radius),
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
            
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
            path.addArc(
                center: CGPoint(x: rect.width - radius, y: rect.height - radius),
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
            
            path.addLine(to: CGPoint(x: radius + tailSize, y: rect.height))
            path.addArc(
                center: CGPoint(x: radius + tailSize, y: rect.height - radius),
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
            
            // Tail
            path.addLine(to: CGPoint(x: tailSize, y: rect.height - radius))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height),
                control: CGPoint(x: tailSize, y: rect.height)
            )
            path.addLine(to: CGPoint(x: tailSize, y: radius))
            
            path.addArc(
                center: CGPoint(x: radius + tailSize, y: radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }
        
        path.closeSubpath()
        return path
    }
}

struct ReactionButton: View {
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(emoji)
                .font(.caption)
                .padding(4)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Message Actions

enum MessageAction {
    case copy
    case delete
    case regenerate
    case showDetails
    case scheduleWorkout
    case viewProgress
    case setReminder
}

// MARK: - Supporting Types

struct ChatChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct ChatQuickAction: Identifiable {
    let id: String
    let title: String
}

// MARK: - Placeholder Views
struct MessageContent: View {
    let text: String
    let isStreaming: Bool
    let role: ChatMessage.Role

    @State private var displayedCount: Int = 0

    private var displayedText: String {
        if isStreaming {
            return String(text.prefix(displayedCount))
        } else {
            return text
        }
    }

    var body: some View {
        Text(displayedText)
            .frame(maxWidth: .infinity, alignment: role == .user ? .trailing : .leading)
            .task(id: text) {
                guard isStreaming else {
                    displayedCount = text.count
                    return
                }
                displayedCount = 0
                for i in 1...text.count {
                    displayedCount = i
                    try? await Task.sleep(for: .milliseconds(20))
                }
            }
    }
}

struct AttachmentThumbnail: View {
    let attachment: ChatAttachment
    let isExpanded: Bool

    var body: some View {
        if let data = attachment.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: isExpanded ? 160 : 80, height: isExpanded ? 160 : 80)
                .clipped()
                .cornerRadius(8)
        } else {
            Image(systemName: attachment.typeEnum.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: isExpanded ? 100 : 50, height: isExpanded ? 100 : 50)
                .padding(isExpanded ? 20 : 10)
                .background(AppColors.cardBackground)
                .cornerRadius(8)
        }
    }
}

struct NavigationLinkCard: View {
    let title: String
    let subtitle: String?
    let destination: String
    let icon: String?

    var body: some View {
        NavigationLink(destination: Text(destination)) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                }
                VStack(alignment: .leading) {
                    Text(title)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.cardBackground))
        }
    }
}

struct ChartView: View {
    let data: [ChatChartDataPoint]
    let isExpanded: Bool

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Label", point.label),
                y: .value("Value", point.value)
            )
            .foregroundStyle(Color.accentColor)
        }
        .frame(height: isExpanded ? 200 : 120)
    }
}

struct ReminderCard: View {
    let time: String
    let title: String
    let isExpanded: Bool

    var body: some View {
        HStack {
            Image(systemName: "bell")
            Text(title)
            Spacer()
            Text("Reminder at \(time)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.cardBackground))
    }
}

struct ProgressCard: View {
    let progress: Double
    let isExpanded: Bool

    var body: some View {
        ProgressView(value: progress)
            .frame(height: isExpanded ? 20 : 12)
    }
}

struct QuickActionsView: View {
    let actions: [ChatQuickAction]
    let onAction: (String) -> Void

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            ForEach(actions) { action in
                Button(action: {
                    onAction(action.id)
                }) {
                    Text(action.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

