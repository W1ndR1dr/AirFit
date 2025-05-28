import SwiftUI
import Charts

struct MessageBubbleView: View {
    let message: ChatMessage
    let isStreaming: Bool
    let onAction: (MessageAction) -> Void

    @State private var showActions = false

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.small) {
            if message.roleEnum == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.roleEnum == .user ? .trailing : .leading, spacing: AppSpacing.xSmall) {
                // Message bubble
                bubble

                // Timestamp and status
                HStack(spacing: AppSpacing.xSmall) {
                    if message.roleEnum == .user && isStreaming {
                        ProgressView()
                            .controlSize(.mini)
                    }

                    Text(message.timestamp.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if message.roleEnum == .assistant {
                Spacer(minLength: 60)
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
            // TODO: Implement rich content based on individual metadata properties
            // if message.functionCallName != nil {
            //     richContentView(for: message.functionCallName!, metadata: [:])
            // }
        }
        .padding()
        .background(bubbleBackground)
        .clipShape(ChatBubbleShape(role: message.roleEnum))
        .contextMenu { messageActions }
    }

    private var bubbleBackground: some View {
        Group {
            if message.roleEnum == .user {
                AppColors.accent.opacity(0.2)
            } else {
                AppColors.cardBackground
            }
        }
    }

    @ViewBuilder
    private var attachmentsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(message.attachments) { attachment in
                    AttachmentThumbnail(attachment: attachment)
                }
            }
        }
    }

    @ViewBuilder
    private func richContentView(for actionType: String, metadata: [String: Any]) -> some View {
        switch actionType {
        case "navigation":
            if let target = metadata["actionTarget"] as? String {
                NavigationLinkCard(
                    title: "View Details",
                    destination: target,
                    icon: "arrow.right.circle.fill"
                )
            }

        case "chart":
            if let chartData = metadata["chartData"] as? [String: Any] {
                MiniChart(data: chartData)
            }

        case "reminder":
            if let time = metadata["reminderTime"] as? String {
                ReminderCard(time: time)
            }

        default:
            EmptyView()
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

        Divider()

        Button(role: .destructive, action: { onAction(.delete) }) {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Supporting Types
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

            // Tail
            path.addArc(
                center: CGPoint(x: radius + tailSize, y: rect.height - radius),
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )

            path.addLine(to: CGPoint(x: tailSize, y: rect.height - radius))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height),
                control: CGPoint(x: tailSize, y: rect.height)
            )
        }

        // Complete the path
        let startX = role == .user ? radius : radius + tailSize
        path.addLine(to: CGPoint(x: startX, y: radius))
        path.addArc(
            center: CGPoint(x: startX, y: radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        return path
    }
}

enum MessageAction {
    case copy
    case delete
    case regenerate
    case showDetails
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

    var body: some View {
        if let data = attachment.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
        } else {
            Image(systemName: attachment.typeEnum.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .padding(10)
                .background(AppColors.cardBackground)
                .cornerRadius(8)
        }
    }
}

struct NavigationLinkCard: View {
    let title: String
    let destination: String
    let icon: String?

    var body: some View {
        NavigationLink(destination: Text(destination)) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.cardBackground))
        }
    }
}

struct MiniChart: View {
    struct Entry: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
    }

    let data: [String: Any]

    private var entries: [Entry] {
        if let points = data["points"] as? [[String: Any]] {
            return points.compactMap { dict in
                if let label = dict["label"] as? String,
                   let value = dict["value"] as? Double {
                    return Entry(label: label, value: value)
                }
                return nil
            }
        }
        return []
    }

    var body: some View {
        Chart(entries) { item in
            BarMark(
                x: .value("Label", item.label),
                y: .value("Value", item.value)
            )
            .foregroundStyle(Color.accentColor)
        }
        .frame(height: 120)
    }
}

struct ReminderCard: View {
    let time: String

    var body: some View {
        HStack {
            Image(systemName: "bell")
            Text("Reminder at \(time)")
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.cardBackground))
    }
}

