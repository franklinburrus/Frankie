import Foundation

/// Locked Phase 1 YouTube thumbnail export profile.
///
/// YouTube Help (support.google.com/youtube/answer/72431, retrieved 2026-11-09)
/// recommends 3840×2160 for video thumbnails, JPG/PNG, 16:9, under upload size
/// limits. Phase 1 locks **1280×720** JPEG/PNG as the MVP profile: still a valid
/// 16:9 YouTube-compatible size used widely in practice and sufficient for
/// first-slice verification. A higher-resolution profile can be added later
/// without changing the pipeline contract.
public struct ExportProfile: Codable, Sendable, Equatable {
    public var id: String
    public var width: Int
    public var height: Int
    public var format: ImageFormat
    public var maxBytes: Int
    public var documentationURL: String
    public var notes: String

    public enum ImageFormat: String, Codable, Sendable {
        case jpeg
        case png
    }

    public static let youtubePhase1 = ExportProfile(
        id: "youtube-phase1-1280x720",
        width: 1280,
        height: 720,
        format: .jpeg,
        maxBytes: 2 * 1024 * 1024,
        documentationURL: "https://support.google.com/youtube/answer/72431?hl=en",
        notes: "Phase 1 lock: 1280×720 JPEG. Help also recommends 3840×2160; deferred."
    )

    public init(
        id: String,
        width: Int,
        height: Int,
        format: ImageFormat,
        maxBytes: Int,
        documentationURL: String,
        notes: String
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.format = format
        self.maxBytes = maxBytes
        self.documentationURL = documentationURL
        self.notes = notes
    }

    public func validate(imageData: Data, width: Int, height: Int) throws {
        if width != self.width || height != self.height {
            throw FrankieError.exportValidationFailed(
                "dimensions \(width)x\(height) != \(self.width)x\(self.height)"
            )
        }
        if imageData.count > maxBytes {
            throw FrankieError.exportValidationFailed(
                "size \(imageData.count) exceeds maxBytes \(maxBytes)"
            )
        }
        if imageData.isEmpty {
            throw FrankieError.exportValidationFailed("empty image data")
        }
    }
}
