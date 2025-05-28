import SwiftData
import Foundation

@Model
final class ChatAttachment: @unchecked Sendable {
    // MARK: - Properties
    var id: UUID
    var type: String // "image", "document", "data"
    var filename: String
    var mimeType: String?
    @Attribute(.externalStorage)
    var data: Data
    var thumbnailData: Data?
    var metadata: Data? // JSON encoded metadata
    var uploadedAt: Date

    // MARK: - Relationships
    var message: ChatMessage?

    // MARK: - Computed Properties
    var fileSize: Int {
        data.count
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }

    var attachmentType: AttachmentType? {
        AttachmentType(rawValue: type)
    }

    var isImage: Bool {
        attachmentType == .image
    }

    var isDocument: Bool {
        attachmentType == .document
    }

    var fileExtension: String? {
        URL(string: filename)?.pathExtension
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        type: AttachmentType,
        filename: String,
        data: Data,
        mimeType: String? = nil
    ) {
        self.id = id
        self.type = type.rawValue
        self.filename = filename
        self.data = data
        self.mimeType = mimeType
        self.uploadedAt = Date()
    }

    // MARK: - Methods
    func generateThumbnail() {
        // Thumbnail generation would be implemented based on type
        // For now, we'll leave it as a placeholder
    }

    func setMetadata(_ dict: [String: Any]) {
        metadata = try? JSONSerialization.data(withJSONObject: dict)
    }

    func getMetadata() -> [String: Any]? {
        guard let data = metadata else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

// MARK: - AttachmentType Enum
enum AttachmentType: String, Sendable {
    case image
    case document
    case data

    var systemImage: String {
        switch self {
        case .image: return "photo"
        case .document: return "doc"
        case .data: return "doc.text"
        }
    }
}
