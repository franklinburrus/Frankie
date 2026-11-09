import Foundation

/// Deterministic readable caption overlay. Exact caption text only — no model rewrite.
public enum CaptionOverlay {
    public static func bandRect(canvasWidth: Int, canvasHeight: Int, preset: LayoutPreset) -> PixelRect {
        let bandHeight = max(48, Int(Double(canvasHeight) * preset.captionBandHeightFraction))
        return PixelRect(
            x: 0,
            y: canvasHeight - bandHeight,
            width: canvasWidth,
            height: bandHeight
        )
    }

    /// Draws an opaque caption band and stamps a high-contrast glyph mask for each
    /// character using a fixed 5×7 bitmap font so tests can assert legibility
    /// without AppKit text layout.
    public static func apply(
        to image: inout RGBAImage,
        caption: String,
        preset: LayoutPreset
    ) {
        let band = bandRect(
            canvasWidth: image.width,
            canvasHeight: image.height,
            preset: preset
        )
        image.fill(rect: band, r: 0, g: 0, b: 0, a: 230)

        let glyphW = 6
        let glyphH = 8
        let scale = max(2, band.height / 18)
        let text = String(caption.prefix(48))
        let totalWidth = text.count * glyphW * scale
        var x = max(16, (image.width - totalWidth) / 2)
        let y = band.y + max(4, (band.height - glyphH * scale) / 2)

        for ch in text.uppercased() {
            drawGlyph(ch, into: &image, x: x, y: y, scale: scale)
            x += glyphW * scale
            if x > image.width - 16 { break }
        }
    }

    private static func drawGlyph(
        _ ch: Character,
        into image: inout RGBAImage,
        x: Int,
        y: Int,
        scale: Int
    ) {
        let rows = BitmapFont.rows(for: ch)
        for (rowIndex, row) in rows.enumerated() {
            for col in 0..<5 {
                if (row & (1 << (4 - col))) != 0 {
                    let rect = PixelRect(
                        x: x + col * scale,
                        y: y + rowIndex * scale,
                        width: scale,
                        height: scale
                    )
                    image.fill(rect: rect, r: 255, g: 255, b: 255, a: 255)
                }
            }
        }
    }
}

enum BitmapFont {
    static func rows(for ch: Character) -> [UInt8] {
        switch ch {
        case "A": return [0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001]
        case "B": return [0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110]
        case "C": return [0b01110, 0b10001, 0b10000, 0b10000, 0b10000, 0b10001, 0b01110]
        case "D": return [0b11110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b11110]
        case "E": return [0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111]
        case "F": return [0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000]
        case "G": return [0b01110, 0b10001, 0b10000, 0b10111, 0b10001, 0b10001, 0b01110]
        case "H": return [0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001]
        case "I": return [0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110]
        case "J": return [0b00111, 0b00010, 0b00010, 0b00010, 0b10010, 0b10010, 0b01100]
        case "K": return [0b10001, 0b10010, 0b10100, 0b11000, 0b10100, 0b10010, 0b10001]
        case "L": return [0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111]
        case "M": return [0b10001, 0b11011, 0b10101, 0b10001, 0b10001, 0b10001, 0b10001]
        case "N": return [0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001, 0b10001]
        case "O": return [0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110]
        case "P": return [0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000]
        case "Q": return [0b01110, 0b10001, 0b10001, 0b10001, 0b10101, 0b10010, 0b01101]
        case "R": return [0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001]
        case "S": return [0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110]
        case "T": return [0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100]
        case "U": return [0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110]
        case "V": return [0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100]
        case "W": return [0b10001, 0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b01010]
        case "X": return [0b10001, 0b10001, 0b01010, 0b00100, 0b01010, 0b10001, 0b10001]
        case "Y": return [0b10001, 0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b00100]
        case "Z": return [0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b11111]
        case "0": return [0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110]
        case "1": return [0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110]
        case "2": return [0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111]
        case "3": return [0b11110, 0b00001, 0b00001, 0b01110, 0b00001, 0b00001, 0b11110]
        case "4": return [0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010]
        case "5": return [0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110]
        case "6": return [0b01110, 0b10000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110]
        case "7": return [0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000]
        case "8": return [0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110]
        case "9": return [0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00001, 0b01110]
        case " ": return [0, 0, 0, 0, 0, 0, 0]
        case "-": return [0, 0, 0, 0b11111, 0, 0, 0]
        case "'": return [0b00100, 0b00100, 0, 0, 0, 0, 0]
        case "!": return [0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0, 0b00100]
        case "?": return [0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0, 0b00100]
        case ".": return [0, 0, 0, 0, 0, 0, 0b00100]
        case ":": return [0, 0b00100, 0, 0, 0b00100, 0, 0]
        default: return [0b11111, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b11111]
        }
    }
}
