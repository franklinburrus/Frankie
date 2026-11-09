import Foundation

/// Import → generate → caption → preview/export orchestration.
public struct ThumbnailPipeline: Sendable {
    public var generator: any LocalImageGenerating

    public init(generator: (any LocalImageGenerating)? = nil) {
        self.generator = generator ?? GeneratorDiscovery().resolve()
    }

    public static func loadSources(
        participantPhotos: [URL],
        references: [URL]
    ) throws -> [SourceAsset] {
        var assets: [SourceAsset] = []
        for url in participantPhotos {
            assets.append(
                SourceAsset(url: url, role: .participantPhoto, sha256: try FileHash.sha256(ofFileAt: url))
            )
        }
        for url in references {
            assets.append(
                SourceAsset(url: url, role: .referenceExample, sha256: try FileHash.sha256(ofFileAt: url))
            )
        }
        return assets
    }

    public func run(
        caption: String,
        styleText: String,
        layoutPresetID: String,
        sources: [SourceAsset],
        exportDirectory: URL,
        exportProfile: ExportProfile = .youtubePhase1
    ) async throws -> (ThumbnailResult, JobRecord) {
        guard sources.contains(where: { $0.role == .participantPhoto }) else {
            throw FrankieError.missingSources
        }

        let request = ThumbnailRequest(
            caption: caption,
            style: StyleInstruction(text: styleText, layoutPresetID: layoutPresetID),
            sources: sources,
            exportProfile: exportProfile
        )

        let result = try await generator.generate(request: request)
        try FileHash.assertUnchanged(sources)

        try FileManager.default.createDirectory(
            at: exportDirectory,
            withIntermediateDirectories: true
        )

        let ext = result.format == .png ? "png" : "jpg"
        let exportURL = exportDirectory.appendingPathComponent("thumbnail.\(ext)")
        try result.imageData.write(to: exportURL, options: .atomic)

        let exportHash = FileHash.sha256(of: result.imageData)
        var sourceHashes: [String: String] = [:]
        for source in sources {
            sourceHashes[source.url.lastPathComponent] = source.sha256
        }

        var review = result.reviewState
        if review == .ready {
            // Pipeline itself never auto-promotes to READY.
            review = .needsReview
        }

        let record = JobRecord(
            request: request,
            provenance: result.provenance,
            reviewState: review,
            exportPath: exportURL.path,
            exportSHA256: exportHash,
            sourceHashes: sourceHashes,
            notes: result.notes,
            evidenceClass: .unknown
        )
        let sidecar = exportDirectory.appendingPathComponent("job-record.json")
        try record.writing(to: sidecar)
        return (result, record)
    }
}
