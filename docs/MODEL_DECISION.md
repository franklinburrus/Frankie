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
| Frank’s Mac | **UNKNOWN** until `Tools/inventory-image-stack.sh` runs there |

## Install proposal (D09)

**PROPOSED only if Mac inventory finds no suitable local runner:**

- Smallest candidate class: already-licensed local CLI that can accept reference images and emit a still, **or** continue with composite path honestly labelled non-AI until Frank picks a model.
- Do **not** download weights or install packages until Frank approves.

Current code default: composite fallback with `NEEDS_REVIEW`. No silent installs.
