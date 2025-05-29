import SwiftUI
import Charts

struct MessageBubbleView: View {
    let message: ChatMessage
    let isStreaming: Bool
    let onAction: (MessageAction) -> Void
    
    @State private var showActions = false
    @State private var isExpanded = false
    @State private var animateIn = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: AppSpacing.xs) {
                // Message bubble
                bubble
                    .scaleEffect(animateIn ? 1.0 : 0.8)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateIn)
                
                // Timestamp and status
                messageFooter
            }
            
            if message.role == .assistant {
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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Attachments
            if !message.attachments.isEmpty {
                attachmentsView
            }
            
            // Message content
            if !message.content.isEmpty {
                MessageContent(
                    text: message.content,
                    isStreaming: isStreaming,
                    role: message.role
                )
            }
            
            // Rich content (charts, buttons, etc)
            richContentView
            
            // Interactive elements
            if message.role == .assistant {
                interactiveElements
            }
        }
        .padding()
        .background(bubbleBackground)
        .clipShape(ChatBubbleShape(role: message.role))
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
    
    private var bubbleBackground: some View {
        Group {
            if message.role == .user {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.cardBackground
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
    
    @ViewBuilder
    private var attachmentsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
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
    private var richContentView: some View {
        if let metadata = message.metadata {
            VStack(spacing: AppSpacing.sm) {
                // Charts
                if let chartData = metadata["chartData"] as? [String: Any] {
                    ChartView(
                        data: chartData,
                        isExpanded: isExpanded
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
                
                // Navigation cards
                if let actionType = metadata["actionType"] as? String,
                   actionType == "navigation",
                   let target = metadata["actionTarget"] as? String {
                    NavigationLinkCard(
                        title: metadata["actionTitle"] as? String ?? "View Details",
                        subtitle: metadata["actionSubtitle"] as? String,
                        destination: target,
                        icon: metadata["actionIcon"] as? String ?? "arrow.right.circle.fill"
                    )
                }
                
                // Reminder cards
                if let reminderTime = metadata["reminderTime"] as? String {
                    ReminderCard(
                        time: reminderTime,
                        title: metadata["reminderTitle"] as? String ?? "Reminder Set",
                        isExpanded: isExpanded
                    )
                }
                
                // Progress indicators
                if let progressData = metadata["progress"] as? [String: Any] {
                    ProgressCard(
                        data: progressData,
                        isExpanded: isExpanded
                    )
                }
                
                // Quick actions
                if let actions = metadata["quickActions"] as? [[String: Any]] {
                    QuickActionsView(
                        actions: actions,
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
        if message.role == .assistant && !isStreaming {
            HStack(spacing: AppSpacing.sm) {
                // Reaction buttons
                HStack(spacing: 4) {
                    ReactionButton(
                        emoji: "👍",
                        isSelected: message.metadata?["reaction"] as? String == "👍",
                        onTap: { toggleReaction("👍") }
                    )
                    
                    ReactionButton(
                        emoji: "👎",
                        isSelected: message.metadata?["reaction"] as? String == "👎",
                        onTap: { toggleReaction("👎") }
                    )
                    
                    ReactionButton(
                        emoji: "❤️",
                        isSelected: message.metadata?["reaction"] as? String == "❤️",
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
            .padding(.top, AppSpacing.xs)
            .opacity(0.7)
        }
    }
    
    private var messageFooter: some View {
        HStack(spacing: AppSpacing.xs) {
            if message.role == .user && isStreaming {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.8)
            }
            
            // Timestamp
            Text(formatTimestamp(message.timestamp))
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            // Message status indicators
            if message.role == .user {
                messageStatusIcon
            }
            
            // Token count for assistant messages
            if message.role == .assistant,
               let tokenCount = message.metadata?["tokens"] as? Int {
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
        } else if message.metadata?["error"] != nil {
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
        
        if message.role == .assistant {
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
        guard let metadata = message.metadata else { return false }
        return metadata["chartData"] != nil || 
               metadata["progress"] != nil ||
               !message.attachments.isEmpty
    }
    
    // MARK: - Helper Methods
    
    private func formatTimestamp(_ date: Date) -> String {
        let now = Date()
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
        // Update message metadata with reaction
        var metadata = message.metadata ?? [:]
        if metadata["reaction"] as? String == emoji {
            metadata.removeValue(forKey: "reaction")
        } else {
            metadata["reaction"] = emoji
        }
        message.metadata = metadata
        
        // Haptic feedback
        Task {
            await HapticManager.shared.impact(.light)
        }
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
    let data: [String: Any]
    let isExpanded: Bool

    var body: some View {
        Chart(data: data) {
            BarMark(
                x: .value("Label", $0.key),
                y: .value("Value", $0.value)
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
    let data: [String: Any]
    let isExpanded: Bool

    var body: some View {
        ProgressView()
            .frame(height: isExpanded ? 20 : 12)
    }
}

struct QuickActionsView: View {
    let actions: [[String: Any]]
    let onAction: (String) -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(actions) { action in
                Button(action: {
                    if let id = action["id"] as? String {
                        onAction(id)
                    }
                }) {
                    Text(action["title"] as? String ?? "Action")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

