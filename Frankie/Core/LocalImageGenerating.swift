import Foundation

/// Pluggable local image generation / composition.
/// Implementations must set `provenance.isAIImageGeneration` honestly.
public protocol LocalImageGenerating: Sendable {
    var provenance: GeneratorProvenance { get }
    func generate(request: ThumbnailRequest) async throws -> ThumbnailResult
}

/// Discovers configured CLI runners and common local tools, then falls back.
public struct GeneratorDiscovery: Sendable {
    public var configuredCLIPath: String?
    public var environment: [String: String]

    public init(
        configuredCLIPath: String? = ProcessInfo.processInfo.environment["FRANKIE_IMAGE_CLI"],
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.configuredCLIPath = configuredCLIPath
        self.environment = environment
    }

    /// Discovery order: configured CLI → discovered local tools → DeterministicCompositeGenerator.
    public func resolve() -> any LocalImageGenerating {
        if let configuredCLIPath, !configuredCLIPath.isEmpty,
           FileManager.default.isExecutableFile(atPath: configuredCLIPath) {
            return ConfiguredCLIGenerator(executablePath: configuredCLIPath)
        }

        if let discovered = discoverLocalTool() {
            return discovered
        }

        return DeterministicCompositeGenerator()
    }

    public func inventoryCandidates() -> [DiscoveredCandidate] {
        var found: [DiscoveredCandidate] = []
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates: [(String, String)] = [
            ("diffusionbee", "\(home)/Applications/DiffusionBee.app"),
            ("draw-things", "\(home)/Applications/Draw Things.app"),
            ("stable-diffusion-webui", "\(home)/stable-diffusion-webui"),
            ("comfyui", "\(home)/ComfyUI"),
            ("mlx-examples", "\(home)/mlx-examples"),
            ("coreml-models", "\(home)/Models"),
            ("ollama", "/usr/local/bin/ollama")
        ]
        for (id, path) in candidates {
            if FileManager.default.fileExists(atPath: path) {
                found.append(DiscoveredCandidate(id: id, path: path, present: true))
            } else {
                found.append(DiscoveredCandidate(id: id, path: path, present: false))
            }
        }
        if let configuredCLIPath {
            found.append(
                DiscoveredCandidate(
                    id: "configured-cli",
                    path: configuredCLIPath,
                    present: FileManager.default.isExecutableFile(atPath: configuredCLIPath)
                )
            )
        }
        return found
    }

    private func discoverLocalTool() -> (any LocalImageGenerating)? {
        // No silent installs. Only wire a discovered tool when FRANKIE_IMAGE_CLI is set
        // or a future Frank-approved adapter is registered. Discovery alone does not
        // activate third-party runners (D09).
        return nil
    }
}

public struct DiscoveredCandidate: Codable, Sendable, Equatable {
    public var id: String
    public var path: String
    public var present: Bool
}

/// Optional configured CLI adapter. Invokes an owner-approved local executable.
/// Not labelled as AI generation unless the CLI reports that itself; Frankie
/// records it as configuredCLI and leaves AI claims to the operator.
public struct ConfiguredCLIGenerator: LocalImageGenerating {
    public var executablePath: String

    public var provenance: GeneratorProvenance {
        GeneratorProvenance(
            generatorID: "configured-cli",
            displayName: "Configured local CLI",
            kind: .configuredCLI,
            isAIImageGeneration: false,
            detail: executablePath,
            licenceNote: "Operator must confirm CLI and model licences before READY."
        )
    }

    public init(executablePath: String) {
        self.executablePath = executablePath
    }

    public func generate(request: ThumbnailRequest) async throws -> ThumbnailResult {
        // Phase 1: configured CLI path is recognized for discovery/provenance, but
        // generation falls through to deterministic composite until Frank approves
        // a specific CLI contract. This avoids silent dependency on unknown tools.
        var composite = try await DeterministicCompositeGenerator().generate(request: request)
        composite.provenance = provenance
        composite.notes.append(
            "Configured CLI recorded but not executed; used DeterministicCompositeGenerator output."
        )
        composite.reviewState = .needsReview
        return composite
    }
}
