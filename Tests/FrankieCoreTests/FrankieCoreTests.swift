import Foundation
import XCTest
@testable import FrankieCore

final class FrankieCoreTests: XCTestCase {
    func testExportProfileDimensions() {
        let profile = ExportProfile.youtubePhase1
        XCTAssertEqual(profile.width, 1280)
        XCTAssertEqual(profile.height, 720)
        XCTAssertEqual(profile.format, .jpeg)
    }

    func testExportValidationRejectsWrongSize() {
        let profile = ExportProfile.youtubePhase1
        XCTAssertThrowsError(
            try profile.validate(imageData: Data(repeating: 1, count: 100), width: 640, height: 360)
        )
    }

    func testSourceHashPreservation() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrankieHash-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let photo = dir.appendingPathComponent("p1.raw")
        let image = RGBAImage.solid(width: 32, height: 32, r: 200, g: 40, b: 40)
        try FrankieRaw.encode(image).write(to: photo)
        let hash = try FileHash.sha256(ofFileAt: photo)
        let asset = SourceAsset(url: photo, role: .participantPhoto, sha256: hash)
        try FileHash.assertUnchanged([asset])

        try Data([0x00]).write(to: photo, options: .atomic)
        XCTAssertThrowsError(try FileHash.assertUnchanged([asset]))
    }

    func testCompositeSlotsHeroLeft() {
        let slots = DeterministicCompositeGenerator.photoSlots(
            count: 2,
            canvasWidth: 1280,
            contentHeight: 560,
            placement: .heroLeft
        )
        XCTAssertEqual(slots.count, 2)
        XCTAssertGreaterThan(slots[0].width, slots[1].width)
    }

    func testDeterministicCompositePipeline() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FrankiePipe-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let photoURL = dir.appendingPathComponent("participant.raw")
        let photo = RGBAImage.solid(width: 200, height: 200, r: 30, g: 120, b: 220)
        try FrankieRaw.encode(photo).write(to: photoURL)
        let before = try FileHash.sha256(ofFileAt: photoURL)

        let sources = try ThumbnailPipeline.loadSources(
            participantPhotos: [photoURL],
            references: []
        )
        // Force portable path: composite generator only.
        let pipeline = ThumbnailPipeline(generator: DeterministicCompositeGenerator())
        let exportDir = dir.appendingPathComponent("out", isDirectory: true)
        let (result, record) = try await pipeline.run(
            caption: "HELLO FRANK",
            styleText: "bold",
            layoutPresetID: LayoutPreset.heroLeft.id,
            sources: sources,
            exportDirectory: exportDir,
            exportProfile: ExportProfile(
                id: "test-raw",
                width: 1280,
                height: 720,
                format: .png,
                maxBytes: 20 * 1024 * 1024,
                documentationURL: "test",
                notes: "test uses portable encoder"
            )
        )

        XCTAssertEqual(result.width, 1280)
        XCTAssertEqual(result.height, 720)
        XCTAssertEqual(result.provenance.isAIImageGeneration, false)
        XCTAssertEqual(result.provenance.kind, .deterministicComposite)
        XCTAssertEqual(record.reviewState, .needsReview)
        XCTAssertNotEqual(record.reviewState, .ready)
        XCTAssertEqual(try FileHash.sha256(ofFileAt: photoURL), before)

        let decoded = try ImageIOBridge.decodeEncoded(result.imageData)
        XCTAssertEqual(decoded.width, 1280)
        XCTAssertEqual(decoded.height, 720)

        // Caption band should contain bright pixels from glyph stamps.
        let band = CaptionOverlay.bandRect(
            canvasWidth: 1280,
            canvasHeight: 720,
            preset: .heroLeft
        )
        var bright = 0
        for y in band.y..<720 {
            for x in 0..<1280 {
                let i = (y * 1280 + x) * 4
                if decoded.rgba[i] > 200 && decoded.rgba[i + 1] > 200 && decoded.rgba[i + 2] > 200 {
                    bright += 1
                }
            }
        }
        XCTAssertGreaterThan(bright, 100)
    }

    func testReadyGateBlocksUnvalidated() throws {
        let request = ThumbnailRequest(
            caption: "X",
            style: StyleInstruction(text: ""),
            sources: []
        )
        let record = JobRecord(
            request: request,
            provenance: DeterministicCompositeGenerator().provenance,
            reviewState: .failed,
            sourceHashes: [:],
            notes: []
        )
        XCTAssertThrowsError(try JobRecord.markReady(record))
    }

    func testCompositeMustNotClaimAI() {
        XCTAssertFalse(DeterministicCompositeGenerator().provenance.isAIImageGeneration)
    }

    func testDiscoveryFallsBackToComposite() {
        let discovery = GeneratorDiscovery(configuredCLIPath: "/nonexistent/frankie-cli-image")
        let gen = discovery.resolve()
        XCTAssertEqual(gen.provenance.generatorID, "deterministic-composite")
        XCTAssertFalse(gen.provenance.isAIImageGeneration)
    }
}
