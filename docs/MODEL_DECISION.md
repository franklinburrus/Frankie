# Model decision (Phase 1)

## Architecture lock

Primary abstraction: pluggable `LocalImageGenerating` (`Frankie/Core/LocalImageGenerating.swift`).

### Discovery order

1. **Configured CLI/runner** — `FRANKIE_IMAGE_CLI` executable path (Frank-approved).
2. **Discovered local tools** — inventory only; adapters are not auto-activated (D09).
3. **`DeterministicCompositeGenerator`** — photo collage + style-ish layout + deterministic caption overlay.

### Labelling rule

`DeterministicCompositeGenerator` **MUST NOT** be labelled as AI image generation (`isAIImageGeneration = false`). Collage/overlay alone does not satisfy “completed AI image generation” acceptance when that claim is made.

## Inventory status

| Environment | Status |
|---|---|
| Linux cloud VM | Best-effort inventory run; no Mac generative stack visible → see `MODEL_INVENTORY.md` |
| Frank’s Mac | **VERIFIED 2026-11-09** — no generative image runner; only Homebrew ffmpeg + unrelated Diffusion Studio video editor. See `MODEL_INVENTORY.md`. |

## Locked runtime decision (post-Mac inventory)

- **Active Phase 1 path:** `DeterministicCompositeGenerator` (composite fallback).
- **AI image-generation claim:** **false** / do not label composite as AI.
- **Install proposal (D09):** remains **PROPOSED only** — Mac inventory found no suitable local runner. Do **not** download weights or install packages until Frank approves a specific candidate.

Current code default: composite fallback with `NEEDS_REVIEW`. No silent installs.
