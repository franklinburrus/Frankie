import Foundation

/// Light design presets (2–3). Applied after the MVP path works in tests.
public struct LayoutPreset: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var displayName: String
    public var captionBandHeightFraction: Double
    public var photoPlacement: PhotoPlacement
    public var backgroundHex: String

    public enum PhotoPlacement: String, Codable, Sendable {
        case heroLeft
        case heroRight
        case gridEqual
    }

    public static let heroLeft = LayoutPreset(
        id: "hero-left",
        displayName: "Hero Left",
        captionBandHeightFraction: 0.22,
        photoPlacement: .heroLeft,
        backgroundHex: "#1A1A1A"
    )

    public static let heroRight = LayoutPreset(
        id: "hero-right",
        displayName: "Hero Right",
        captionBandHeightFraction: 0.22,
        photoPlacement: .heroRight,
        backgroundHex: "#102A43"
    )

    public static let gridEqual = LayoutPreset(
        id: "grid-equal",
        displayName: "Equal Grid",
        captionBandHeightFraction: 0.20,
        photoPlacement: .gridEqual,
        backgroundHex: "#243B53"
    )

    public static let all: [LayoutPreset] = [heroLeft, heroRight, gridEqual]

    public static func resolve(_ id: String) -> LayoutPreset {
        all.first(where: { $0.id == id }) ?? heroLeft
    }
}
