# Phase 1 acceptance evidence

- Evidence class: `VERIFIED` (Mac run)
- Generated at: `2026-11-09T22:38:21Z`
- Host: Darwin arm64 — `/Users/frank/Documents/Frankie App`
- Branch / HEAD: `cursor/phase1-thumbnail-mvp-0525` @ `3bf544b2b26e807abb9e80f10085f0bbadb95be8` (pre-evidence-commit)
- Export dir: `artifacts/phase1-acceptance/export`
- Full artifact tree: `artifacts/phase1-acceptance/` (BASELINE.md, MODEL_INVENTORY.md, generate.txt, source-hashes-after.txt, PHASE1_EVIDENCE.md, export/)
- Review state: **`NEEDS_REVIEW`** (not READY — Frank human sign-off still required for likeness/publish)
- Generator: `deterministic-composite` (`DeterministicCompositeGenerator`)
- AI image generation claim: **`false`**
- Export path: `artifacts/phase1-acceptance/export/thumbnail.jpg`
- Export SHA-256: `f385937e45f170ecf2d3eecca19497ec621c17b9c17d895550f3c8345bf426e5`
- Dimensions / format: **1280×720 JPEG** (Phase 1 profile)

## Authorized inputs (Frank-supplied local assets)

Source location (preserved outside working tree during PR checkout):
`/Users/frank/Documents/Frankie-local-untracked-backup-20261109/Assets/`

| Role | File | SHA-256 (before = after) |
|---|---|---|
| Participant | `Participants/joe-budden.jpg` | `3f46331cac1a1689ca68c173b809f30301057324af421571cf10ef24cd01bf26` |
| Participant | `Participants/ish.jpg` | `11ed17404dffc1aff955e360c55435974ba80e0ca132d37a561a14e0f8da491d` |
| Participant | `Participants/queenzflip.jpg` | `220dd1e854e7ff81fb49657ea239c36206fafa9377903a755c140a01223bc4f1` |
| Reference (visual only) | `References/clY-cjxGKqc.jpg` | `d9d7eba6c3db6ec2aa2033a0b8778491b3bb04326376f42c96d5b232549f2054` |

Manifest basis: user-supplied participant labels in `Assets/Participants/manifest.json`. Caption basis: prior authorized editorial summary `FLIP FIRES BACK!` from `Assets/CaptionSources/jbp-974-cast-miami.json` (editorial paraphrase, not a verbatim quote).

## Model provenance

- Active path: composite fallback (Mac inventory found **no** local generative image runner — see `docs/MODEL_INVENTORY.md`)
- `isAIImageGeneration`: false
- No installs performed (D09)

## Checklist

| Check | Result | Class |
|---|---|---|
| Export decodes | PASS (`sips` + visual open) | VERIFIED |
| Dimensions/format = 1280×720 JPEG | PASS | VERIFIED |
| Caption exact + readable | PASS — exact text `FLIP FIRES BACK!` visible on black caption band | VERIFIED |
| Participants recognizable | PASS for Joe Budden (hero-left), Ish (top-right), QueenzFlip (bottom-right) on visual inspection of export | VERIFIED (agent); Frank final likeness OK still open |
| No invented quotes/events | PASS — caption is prior authorized editorial summary, not a fabricated quote | VERIFIED |
| Source hashes unchanged | PASS — before/after SHA-256 identical for all four inputs | VERIFIED |
| Provenance recorded in sidecar | PASS — `export/job-record.json` | VERIFIED |
| Review state not READY unless human-validated | PASS — remains `NEEDS_REVIEW` | VERIFIED |

## Acceptance verdict

**`NEEDS_REVIEW`** — Mac technical acceptance **PASS**. Composite export, hashes, dimensions, caption, and non-AI labelling all verified. Frank should visually confirm likeness/publish readiness before any `READY` promotion. AI image-generation acceptance remains **not claimed** and **not met** (by design until an approved local model exists).

## Commands used

```bash
Tools/verify-mac-baseline.sh
Tools/inventory-image-stack.sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  PATH="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin:$DEVELOPER_DIR/usr/bin:$PATH" \
  swift test
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -scheme Frankie -destination 'platform=macOS' -configuration Debug build
Tools/run-phase1-acceptance.sh \
  --photo …/joe-budden.jpg --photo …/ish.jpg --photo …/queenzflip.jpg \
  --ref …/clY-cjxGKqc.jpg \
  --caption "FLIP FIRES BACK!" \
  --out artifacts/phase1-acceptance
```
