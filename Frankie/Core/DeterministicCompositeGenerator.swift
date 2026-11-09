import Foundation

/// Photo collage + style-ish layout. **Must not** be labelled as AI image generation.
public struct DeterministicCompositeGenerator: LocalImageGenerating {
    public init() {}

    public var provenance: GeneratorProvenance {
        GeneratorProvenance(
            generatorID: "deterministic-composite",
            displayName: "DeterministicCompositeGenerator",
            kind: .deterministicComposite,
            isAIImageGeneration: false,
            detail: "Photo collage with deterministic caption overlay; not AI image generation.",
            licenceNote: "Uses only local participant/reference files supplied by the operator."
        )
    }

    public func generate(request: ThumbnailRequest) async throws -> ThumbnailResult {
        let photos = request.sources.filter { $0.role == .participantPhoto }
        guard !photos.isEmpty else { throw FrankieError.missingSources }

        try FileHash.assertUnchanged(request.sources)

        let profile = request.exportProfile
        let preset = LayoutPreset.resolve(request.style.layoutPresetID)
        let bg = Self.parseHex(preset.backgroundHex)
        var canvas = RGBAImage.solid(
            width: profile.width,
            height: profile.height,
            r: bg.0,
            g: bg.1,
            b: bg.2
        )

        let band = CaptionOverlay.bandRect(
            canvasWidth: profile.width,
            canvasHeight: profile.height,
            preset: preset
        )
        let contentHeight = max(1, profile.height - band.height)
        let slots = Self.photoSlots(
            count: photos.count,
            canvasWidth: profile.width,
            contentHeight: contentHeight,
            placement: preset.photoPlacement
        )

        for (index, photo) in photos.enumerated() {
            let loaded = try loadPhoto(photo.url)
            let slot = slots[min(index, slots.count - 1)]
            canvas.blit(loaded, into: slot)
        }

        // Soft style tint from instruction length (deterministic, not generative).
        if !request.style.text.isEmpty {
            let tintStrength = UInt8(min(40, 8 + request.style.text.count % 32))
            let tintRect = PixelRect(x: 0, y: 0, width: profile.width, height: 8)
            canvas.fill(rect: tintRect, r: 255, g: 200, b: 80, a: tintStrength)
        }

        CaptionOverlay.apply(to: &canvas, caption: request.caption, preset: preset)

        try FileHash.assertUnchanged(request.sources)

        let encoded = try ImageIOBridge.encode(canvas, format: profile.format)
        try profile.validate(imageData: encoded, width: canvas.width, height: canvas.height)

        return ThumbnailResult(
            imageData: encoded,
            format: profile.format,
            width: canvas.width,
            height: canvas.height,
            provenance: provenance,
            reviewState: .needsReview,
            notes: [
                "Deterministic composite path. Not AI image generation.",
                "Caption overlay applied with exact operator caption text.",
                "ReviewState remains NEEDS_REVIEW until human acceptance on authorized media."
            ]
        )
    }

    public static func photoSlots(
        count: Int,
        canvasWidth: Int,
        contentHeight: Int,
        placement: LayoutPreset.PhotoPlacement
    ) -> [PixelRect] {
        let n = max(1, count)
        let pad = 16
        switch placement {
        case .heroLeft:
            if n == 1 {
                return [PixelRect(x: pad, y: pad, width: canvasWidth - pad * 2, height: contentHeight - pad * 2)]
            }
            let heroW = Int(Double(canvasWidth) * 0.62) - pad
            var slots = [
                PixelRect(x: pad, y: pad, width: heroW, height: contentHeight - pad * 2)
            ]
            let sideX = heroW + pad * 2
            let sideW = canvasWidth - sideX - pad
            let sideH = (contentHeight - pad * (n)) / max(1, n - 1)
            for i in 1..<n {
                slots.append(
                    PixelRect(
                        x: sideX,
                        y: pad + (i - 1) * (sideH + pad),
                        width: sideW,
                        height: sideH
                    )
                )
            }
            return slots
        case .heroRight:
            if n == 1 {
                return [PixelRect(x: pad, y: pad, width: canvasWidth - pad * 2, height: contentHeight - pad * 2)]
            }
            let sideW = Int(Double(canvasWidth) * 0.32) - pad
            var slots: [PixelRect] = []
            let sideH = (contentHeight - pad * (n)) / max(1, n - 1)
            for i in 1..<n {
                slots.append(
                    PixelRect(
                        x: pad,
                        y: pad + (i - 1) * (sideH + pad),
                        width: sideW,
                        height: sideH
                    )
                )
            }
            let heroX = sideW + pad * 2
            slots.insert(
                PixelRect(
                    x: heroX,
                    y: pad,
                    width: canvasWidth - heroX - pad,
                    height: contentHeight - pad * 2
                ),
                at: 0
            )
            return slots
        case .gridEqual:
            let cols = min(3, n)
            let rows = Int(ceil(Double(n) / Double(cols)))
            let cellW = (canvasWidth - pad * (cols + 1)) / cols
            let cellH = (contentHeight - pad * (rows + 1)) / rows
            var slots: [PixelRect] = []
            for i in 0..<n {
                let col = i % cols
                let row = i / cols
                slots.append(
                    PixelRect(
                        x: pad + col * (cellW + pad),
                        y: pad + row * (cellH + pad),
                        width: cellW,
                        height: cellH
                    )
                )
            }
            return slots
        }
    }

    private func loadPhoto(_ url: URL) throws -> RGBAImage {
        if let data = try? Data(contentsOf: url),
           let decoded = try? FrankieRaw.decode(data) {
            return decoded
        }
        #if canImport(CoreGraphics)
        return try ImageIOBridge.loadRGBA(from: url)
        #else
        let digest = try FileHash.sha256(ofFileAt: url)
        let r = UInt8(digest.prefix(2), radix: 16) ?? 128
        let g = UInt8(digest.dropFirst(2).prefix(2), radix: 16) ?? 128
        let b = UInt8(digest.dropFirst(4).prefix(2), radix: 16) ?? 128
        return RGBAImage.solid(width: 256, height: 256, r: r, g: g, b: b)
        #endif
    }

    private static func parseHex(_ hex: String) -> (UInt8, UInt8, UInt8) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let intVal = UInt32(value, radix: 16) else {
            return (26, 26, 26)
        }
        return (
            UInt8((intVal >> 16) & 0xFF),
            UInt8((intVal >> 8) & 0xFF),
            UInt8(intVal & 0xFF)
        )
    }
}
