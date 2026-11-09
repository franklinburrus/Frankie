import FrankieCore
import SwiftUI

struct ContentView: View {
    @StateObject private var model = ThumbnailJobViewModel()

    var body: some View {
        HSplitView {
            formColumn
                .frame(minWidth: 320, idealWidth: 360)
            previewColumn
                .frame(minWidth: 480)
        }
        .padding(12)
    }

    private var formColumn: some View {
        Form {
            Section("Sources") {
                Button("Import participant photos…") { model.pickParticipants() }
                Text(fileList(model.participantURLs))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Import reference examples…") { model.pickReferences() }
                Text(fileList(model.referenceURLs))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Caption & style") {
                TextField("Exact caption", text: $model.caption)
                TextField("Style instruction", text: $model.styleText, axis: .vertical)
                    .lineLimit(3...6)
                Picker("Layout preset", selection: $model.layoutPresetID) {
                    ForEach(model.presets) { preset in
                        Text(preset.displayName).tag(preset.id)
                    }
                }
            }

            Section("Generator") {
                Text(model.generatorSummary)
                    .font(.caption)
                Button(model.isBusy ? "Working…" : "Generate thumbnail") {
                    model.generate()
                }
                .disabled(model.isBusy || model.participantURLs.isEmpty || model.caption.isEmpty)
            }

            Section("Status") {
                Text(model.reviewState.rawValue)
                    .foregroundStyle(color(for: model.reviewState))
                Text(model.statusMessage)
                    .font(.caption)
                if let record = model.lastRecord {
                    Text("Sidecar: \(record.exportPath ?? "none").json")
                        .font(.caption2)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var previewColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.headline)
            if let image = model.previewImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .border(Color.secondary.opacity(0.3))
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.08))
                    .overlay(Text("No preview yet").foregroundStyle(.secondary))
            }
            Text("Export profile: \(ExportProfile.youtubePhase1.id) · 1280×720")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private func fileList(_ urls: [URL]) -> String {
        if urls.isEmpty { return "None selected" }
        return urls.map(\.lastPathComponent).joined(separator: ", ")
    }

    private func color(for state: ReviewState) -> Color {
        switch state {
        case .ready: return .green
        case .needsReview: return .orange
        case .failed: return .red
        case .draft: return .secondary
        }
    }
}
