import Foundation
import UniformTypeIdentifiers

struct ChatExporter {
    enum ExportFormat {
        case json
        case markdown
        case txt

        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .markdown: return "md"
            case .txt: return "txt"
            }
        }

        var utType: UTType {
            switch self {
            case .json: return .json
            case .markdown: return .text
            case .txt: return .plainText
            }
        }
    }

    func export(
        session: ChatSession,
        messages: [ChatMessage],
        format: ExportFormat = .markdown
    ) async throws -> URL {
        let content: String
        switch format {
        case .json:
            content = try exportAsJSON(session: session, messages: messages)
        case .markdown:
            content = exportAsMarkdown(session: session, messages: messages)
        case .txt:
            content = exportAsText(session: session, messages: messages)
        }

        let sessionTitle = session.title ?? "Untitled"
        let fileName = "AirFit_Chat_\(sessionTitle)_\(Date().ISO8601Format()).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    private func exportAsJSON(session: ChatSession, messages: [ChatMessage]) throws -> String {
        let exportData = ChatExportData(
            session: SessionExportData(
                id: session.id.uuidString,
                title: session.title ?? "Untitled",
                createdAt: session.createdAt.ISO8601Format(),
                messageCount: messages.count
            ),
            messages: messages.map { message in
                MessageExportData(
                    id: message.id.uuidString,
                    content: message.content,
                    role: message.role,
                    timestamp: message.timestamp.ISO8601Format(),
                    attachments: message.attachments.map { attachment in
                        AttachmentExportData(
                            id: attachment.id.uuidString,
                            type: attachment.type,
                            mimeType: attachment.mimeType ?? "unknown"
                        )
                    }
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func exportAsMarkdown(session: ChatSession, messages: [ChatMessage]) -> String {
        let sessionTitle = session.title ?? "Untitled"
        var markdown = """
        # AirFit Chat Export

        **Session:** \(sessionTitle)
        **Date:** \(session.createdAt.formatted())
        **Messages:** \(messages.count)

        ---
        """

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        for message in messages {
            let role = message.role == "user" ? "You" : "AI Coach"
            let time = formatter.string(from: message.timestamp)
            markdown += "\n**\(role)** _(\(time))_\n\(message.content)\n"

            if !message.attachments.isEmpty {
                markdown += "_[Attachments: \(message.attachments.count)]_\n"
            }
        }

        return markdown
    }

    private func exportAsText(session: ChatSession, messages: [ChatMessage]) -> String {
        let sessionTitle = session.title ?? "Untitled"
        var text = """
        AirFit Chat Export
        Session: \(sessionTitle)
        Date: \(session.createdAt.formatted())
        Messages: \(messages.count)

        =====================================
        """

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        for message in messages {
            let role = message.role == "user" ? "You" : "AI Coach"
            let time = formatter.string(from: message.timestamp)
            text += "\n[\(time)] \(role):\n\(message.content)\n"
        }

        return text
    }
}

// MARK: - Export Data Structures
private struct ChatExportData: Codable {
    let session: SessionExportData
    let messages: [MessageExportData]
}

private struct SessionExportData: Codable {
    let id: String
    let title: String
    let createdAt: String
    let messageCount: Int
}

private struct MessageExportData: Codable {
    let id: String
    let content: String
    let role: String
    let timestamp: String
    let attachments: [AttachmentExportData]
}

private struct AttachmentExportData: Codable {
    let id: String
    let type: String
    let mimeType: String
}
