import CryptoKit
import Foundation

public enum FileHash {
    public static func sha256(ofFileAt url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            let chunk = try handle.read(upToCount: 1024 * 1024) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    public static func sha256(of data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// Re-hash each source and fail if any byte changed.
    public static func assertUnchanged(_ sources: [SourceAsset]) throws {
        for source in sources {
            let current = try sha256(ofFileAt: source.url)
            if current != source.sha256 {
                throw FrankieError.sourceMutated(
                    path: source.url.path,
                    expected: source.sha256,
                    actual: current
                )
            }
        }
    }
}

public enum FrankieError: Error, LocalizedError, Equatable {
    case sourceMutated(path: String, expected: String, actual: String)
    case missingSources
    case exportValidationFailed(String)
    case generatorFailed(String)
    case readyBlocked(String)

    public var errorDescription: String? {
        switch self {
        case let .sourceMutated(path, expected, actual):
            return "Source mutated: \(path) expected \(expected) got \(actual)"
        case .missingSources:
            return "At least one participant photo is required"
        case let .exportValidationFailed(message):
            return "Export validation failed: \(message)"
        case let .generatorFailed(message):
            return "Generator failed: \(message)"
        case let .readyBlocked(message):
            return "READY blocked: \(message)"
        }
    }
}
