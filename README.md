# Frankie

Local native Mac app for **one truthful YouTube thumbnail** (Phase 1). Not Joey. No cloud inference, paid APIs, telemetry, or publishing.

Phase 2 cartoon Shorts are **deferred** and must not gate thumbnails.

## Requirements

- macOS 14+ with Xcode / Swift 6 toolchain (UI + `swift test`)
- Authorized participant photos stay **off-repo** (`Fixtures/authorized/` is gitignored)

## Build / run (Mac)

```bash
# Core library, CLI, unit tests
swift build
swift test
swift run frankie-cli discover

# GUI
open Frankie.xcodeproj
# Product → Run (Frankie)
```

CLI generate:

```bash
swift run frankie-cli generate \
  --photo /path/to/photo.jpg \
  --caption "EXACT CAPTION" \
  --style "match reference" \
  --out artifacts/export
```

## Cloud / Linux verification

This environment has no Swift/macOS SDK. Use:

```bash
python3 Tools/run-cloud-fixtures.py
Tools/verify-mac-baseline.sh docs/BASELINE.md   # works cross-platform for Caveman hashes
Tools/inventory-image-stack.sh                  # best-effort; Mac models stay UNKNOWN
```

Authorized-media acceptance remains **BLOCKED** without a Mac:

```bash
Tools/run-phase1-acceptance.sh --photo PATH --caption "TEXT"
```

## Docs

| Doc | Purpose |
|---|---|
| `docs/START_HERE.md` | Mirror of Frankie 01 |
| `docs/SCOPE_ACCEPTANCE.md` | Mirror of Frankie 02 |
| `docs/DECISIONS.md` | Mirror of Frankie 03 + implementation locks |
| `docs/EXPORT_PROFILE.md` | 1280×720 Phase 1 profile |
| `docs/MODEL_DECISION.md` | Generator discovery + composite labelling |
| `docs/BASELINE.md` | Caveman / baseline evidence |
| `docs/MODEL_INVENTORY.md` | Inventory evidence |
| `docs/PHASE1_EVIDENCE.md` | Acceptance template (Mac) |
| `docs/STATUS.md` | Current status |

Authoritative Drive docs: Frankie 01–05 (linked from the mirrors).

## Caveman

Protected package restored from Joey commit `244a72d822987e302e7ce5d9755e4ae190880e44`. See `third_party/caveman/provenance.json` and `AGENTS.md` (Frankie-specific; Ultra by default).
