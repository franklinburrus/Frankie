import Foundation

/// Persisted job + export sidecar provenance.
public struct JobRecord: Codable, Sendable, Equatable {
    public var id: String
    public var createdAt: Date
    public var request: ThumbnailRequest
    public var provenance: GeneratorProvenance
    public var reviewState: ReviewState
    public var exportPath: String?
    public var exportSHA256: String?
    public var sourceHashes: [String: String]
    public var notes: [String]
    public var evidenceClass: EvidenceClass

    public init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        request: ThumbnailRequest,
        provenance: GeneratorProvenance,
        reviewState: ReviewState,
        exportPath: String? = nil,
        exportSHA256: String? = nil,
        sourceHashes: [String: String],
        notes: [String],
        evidenceClass: EvidenceClass = .unknown
    ) {
        self.id = id
        self.createdAt = createdAt
        self.request = request
        self.provenance = provenance
        self.reviewState = reviewState
        self.exportPath = exportPath
        self.exportSHA256 = exportSHA256
        self.sourceHashes = sourceHashes
        self.notes = notes
        self.evidenceClass = evidenceClass
    }

    public func writing(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(self).write(to: url, options: .atomic)
    }

    public static func markReady(_ record: JobRecord) throws -> JobRecord {
        guard record.reviewState == .needsReview else {
            throw FrankieError.readyBlocked(
                "Only NEEDS_REVIEW jobs may become READY after human validation; current=\(record.reviewState.rawValue)"
            )
        }
        guard record.exportPath != nil, record.exportSHA256 != nil else {
            throw FrankieError.readyBlocked("Export path and hash required before READY")
        }
        if record.provenance.kind == .deterministicComposite, record.provenance.isAIImageGeneration {
            throw FrankieError.readyBlocked("Composite path incorrectly labelled as AI generation")
        }
        var next = record
        next.reviewState = .ready
        next.notes.append("Marked READY after human validation.")
        return next
    }
}
