import AppKit
import Foundation
import FrankieCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class ThumbnailJobViewModel: ObservableObject {
    @Published var caption: String = ""
    @Published var styleText: String = ""
    @Published var layoutPresetID: String = LayoutPreset.heroLeft.id
    @Published var participantURLs: [URL] = []
    @Published var referenceURLs: [URL] = []
    @Published var previewImage: NSImage?
    @Published var statusMessage: String = "Import photos, set caption, then Generate."
    @Published var reviewState: ReviewState = .draft
    @Published var lastRecord: JobRecord?
    @Published var generatorSummary: String = ""
    @Published var isBusy = false

    private let pipeline: ThumbnailPipeline

    init(pipeline: ThumbnailPipeline = ThumbnailPipeline()) {
        self.pipeline = pipeline
        let discovered = GeneratorDiscovery().resolve()
        generatorSummary =
            "\(discovered.provenance.displayName) · AI claim=\(discovered.provenance.isAIImageGeneration)"
    }

    var presets: [LayoutPreset] { LayoutPreset.all }

    func pickParticipants() {
        participantURLs = Self.pickImages(allowingMultiple: true)
    }

    func pickReferences() {
        referenceURLs = Self.pickImages(allowingMultiple: true)
    }

    func generate() {
        guard !isBusy else { return }
        isBusy = true
        statusMessage = "Generating…"
        Task {
            defer { isBusy = false }
            do {
                let sources = try ThumbnailPipeline.loadSources(
                    participantPhotos: participantURLs,
                    references: referenceURLs
                )
                let exportDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("FrankieExport-\(UUID().uuidString)", isDirectory: true)
                let (result, record) = try await pipeline.run(
                    caption: caption,
                    styleText: styleText,
                    layoutPresetID: layoutPresetID,
                    sources: sources,
                    exportDirectory: exportDir
                )
                lastRecord = record
                reviewState = record.reviewState
                previewImage = NSImage(data: result.imageData)
                statusMessage =
                    "Export \(record.exportPath ?? "") · \(record.reviewState.rawValue) · \(result.provenance.displayName)"
                if result.provenance.isAIImageGeneration == false,
                   result.provenance.kind == .deterministicComposite {
                    statusMessage += " · NOT AI image generation"
                }
            } catch {
                reviewState = .failed
                previewImage = nil
                statusMessage = "FAILED: \(error.localizedDescription)"
            }
        }
    }

    private static func pickImages(allowingMultiple: Bool) -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .heic, .webP]
        panel.allowsMultipleSelection = allowingMultiple
        panel.canChooseDirectories = false
        return panel.runModal() == .OK ? panel.urls : []
    }
}
