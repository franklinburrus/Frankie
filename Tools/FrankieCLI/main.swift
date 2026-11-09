import Foundation
import FrankieCore

@main
struct FrankieCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let command = args.first else {
            printUsage()
            exit(2)
        }

        do {
            switch command {
            case "generate":
                try await generate(Array(args.dropFirst()))
            case "discover":
                discover()
            case "hash":
                try hashFiles(Array(args.dropFirst()))
            default:
                printUsage()
                exit(2)
            }
        } catch {
            fputs("FAILED: \(error)\n", stderr)
            exit(1)
        }
    }

    static func generate(_ args: [String]) async throws {
        var photos: [URL] = []
        var refs: [URL] = []
        var caption = ""
        var style = ""
        var preset = LayoutPreset.heroLeft.id
        var out = URL(fileURLWithPath: "artifacts/phase1-export", isDirectory: true)

        var i = 0
        while i < args.count {
            let arg = args[i]
            switch arg {
            case "--photo":
                i += 1; photos.append(URL(fileURLWithPath: args[i]))
            case "--ref":
                i += 1; refs.append(URL(fileURLWithPath: args[i]))
            case "--caption":
                i += 1; caption = args[i]
            case "--style":
                i += 1; style = args[i]
            case "--preset":
                i += 1; preset = args[i]
            case "--out":
                i += 1; out = URL(fileURLWithPath: args[i], isDirectory: true)
            default:
                throw FrankieError.generatorFailed("Unknown argument: \(arg)")
            }
            i += 1
        }

        guard !photos.isEmpty, !caption.isEmpty else {
            throw FrankieError.generatorFailed("--photo and --caption are required")
        }

        let sources = try ThumbnailPipeline.loadSources(
            participantPhotos: photos,
            references: refs
        )
        let pipeline = ThumbnailPipeline()
        let (result, record) = try await pipeline.run(
            caption: caption,
            styleText: style,
            layoutPresetID: preset,
            sources: sources,
            exportDirectory: out
        )

        print("export=\(record.exportPath ?? "")")
        print("sha256=\(record.exportSHA256 ?? "")")
        print("review=\(record.reviewState.rawValue)")
        print("generator=\(result.provenance.generatorID)")
        print("ai_image_generation=\(result.provenance.isAIImageGeneration)")
        print("width=\(result.width)")
        print("height=\(result.height)")
    }

    static func discover() {
        let discovery = GeneratorDiscovery()
        let selected = discovery.resolve()
        print("selected=\(selected.provenance.generatorID)")
        print("ai_image_generation=\(selected.provenance.isAIImageGeneration)")
        for candidate in discovery.inventoryCandidates() {
            print("candidate id=\(candidate.id) present=\(candidate.present) path=\(candidate.path)")
        }
    }

    static func hashFiles(_ args: [String]) throws {
        for path in args {
            let url = URL(fileURLWithPath: path)
            print("\(try FileHash.sha256(ofFileAt: url))  \(path)")
        }
    }

    static func printUsage() {
        fputs(
            """
            frankie-cli generate --photo PATH [--photo PATH...] [--ref PATH...] --caption TEXT [--style TEXT] [--preset ID] [--out DIR]
            frankie-cli discover
            frankie-cli hash PATH...

            """,
            stderr
        )
    }
}
