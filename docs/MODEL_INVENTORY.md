# Frankie model inventory

- Evidence class: `VERIFIED`
- Generated at: `2026-11-09T22:31:36Z`
- Host: `Darwin` / `arm64`
- Repo: `/Users/frank/Documents/Frankie App` on branch `cursor/phase1-thumbnail-mvp-0525` @ `3bf544b2b26e807abb9e80f10085f0bbadb95be8`

## Candidates

- diffusionbee: present=false path=/Users/frank/Applications/DiffusionBee.app
- draw-things: present=false path=/Users/frank/Applications/Draw Things.app
- automatic1111: present=false path=/Users/frank/stable-diffusion-webui
- comfyui: present=false path=/Users/frank/ComfyUI
- mlx: present=false path=/Users/frank/mlx-examples
- coreml-models: present=false path=/Users/frank/Models
- ollama: present=false path=/usr/local/bin/ollama
- ollama-homebrew: present=false path=/opt/homebrew/bin/ollama
- ffmpeg: present=false path=/usr/local/bin/ffmpeg
- ffmpeg-homebrew: present=true path=/opt/homebrew/bin/ffmpeg
- ffmpeg-path: present=true path=/opt/homebrew/bin/ffmpeg

## Mac VERIFIED findings (2026-11-09)

| Finding | Result |
|---|---|
| Local generative image runner (DiffusionBee / Draw Things / A1111 / ComfyUI / MLX examples) | **None present** |
| Dedicated `~/Models` Core ML image weights | **Absent** |
| Bounded Core ML scan under `~/Library/Application Support` + `/opt` | **0** image-gen hits |
| Broader Spotlight `.mlmodelc` hits | System/speech (Siri), Teams temp, PersonalizationPortrait — **not** Frankie image-gen stack |
| `/Applications/Diffusion Studio.app` | Present (`studio.diffusion.editor`) — video editor, **not** a still image-generation runner |
| Homebrew `ffmpeg` | Present at `/opt/homebrew/bin/ffmpeg` |
| Fonts | System/user font directories present (individual licence check still required) |
| Installs performed this run | **None** (D09) |

## Implication

No Frank-approved local AI image model/runner is available on this Mac. Phase 1 continues on **`DeterministicCompositeGenerator`** (non-AI-labelled collage/overlay). Any new model/runner install remains **PROPOSED only** until Frank explicitly approves (D09).

## Notes

- Candidate scan completed on Frank's Mac via `Tools/inventory-image-stack.sh` (script hardened so missing `~/Models` no longer trips `pipefail`).
- No installs performed (D09).

Machine-readable: `docs/model-inventory.json`
