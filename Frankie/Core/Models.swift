import Foundation

/// Evidence classification used in Frankie docs and job records.
public enum EvidenceClass: String, Codable, Sendable {
    case verified = "VERIFIED"
    case reported = "REPORTED"
    case proposed = "PROPOSED"
    case unknown = "UNKNOWN"
}

/// Job / export readiness. Unvalidated output must never become `.ready`.
public enum ReviewState: String, Codable, Sendable {
    case draft = "DRAFT"
    case needsReview = "NEEDS_REVIEW"
    case failed = "FAILED"
    case ready = "READY"
}

public struct SourceAsset: Codable, Sendable, Equatable {
    public var url: URL
    public var role: Role
    public var sha256: String

    public enum Role: String, Codable, Sendable {
        case participantPhoto
        case referenceExample
    }

    public init(url: URL, role: Role, sha256: String) {
        self.url = url
        self.role = role
        self.sha256 = sha256
    }
}

public struct StyleInstruction: Codable, Sendable, Equatable {
    public var text: String
    public var layoutPresetID: String

    public init(text: String, layoutPresetID: String = LayoutPreset.heroLeft.id) {
        self.text = text
        self.layoutPresetID = layoutPresetID
    }
}

public struct ThumbnailRequest: Codable, Sendable, Equatable {
    public var caption: String
    public var style: StyleInstruction
    public var sources: [SourceAsset]
    public var exportProfile: ExportProfile

    public init(
        caption: String,
        style: StyleInstruction,
        sources: [SourceAsset],
        exportProfile: ExportProfile = .youtubePhase1
    ) {
        self.caption = caption
        self.style = style
        self.sources = sources
        self.exportProfile = exportProfile
    }
}

public struct GeneratorProvenance: Codable, Sendable, Equatable {
    public var generatorID: String
    public var displayName: String
    public var kind: Kind
    public var isAIImageGeneration: Bool
    public var detail: String
    public var licenceNote: String

    public enum Kind: String, Codable, Sendable {
        case configuredCLI
        case discoveredLocalTool
        case deterministicComposite
    }

    public init(
        generatorID: String,
        displayName: String,
        kind: Kind,
        isAIImageGeneration: Bool,
        detail: String,
        licenceNote: String
    ) {
        self.generatorID = generatorID
        self.displayName = displayName
        self.kind = kind
        self.isAIImageGeneration = isAIImageGeneration
        self.detail = detail
        self.licenceNote = licenceNote
    }
}

public struct ThumbnailResult: Sendable {
    public var imageData: Data
    public var format: ExportProfile.ImageFormat
    public var width: Int
    public var height: Int
    public var provenance: GeneratorProvenance
    public var reviewState: ReviewState
    public var notes: [String]

    public init(
        imageData: Data,
        format: ExportProfile.ImageFormat,
        width: Int,
        height: Int,
        provenance: GeneratorProvenance,
        reviewState: ReviewState,
        notes: [String]
    ) {
        self.imageData = imageData
        self.format = format
        self.width = width
        self.height = height
        self.provenance = provenance
        self.reviewState = reviewState
        self.notes = notes
    }
}
