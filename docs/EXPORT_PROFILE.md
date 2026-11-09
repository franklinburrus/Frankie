# Phase 1 export profile

## Chosen profile

| Field | Value |
|---|---|
| ID | `youtube-phase1-1280x720` |
| Dimensions | **1280 × 720** |
| Aspect | 16:9 |
| Formats | JPEG (default) or PNG |
| Max bytes (local guard) | 2 MiB |
| Source | Code lock in `ExportProfile.youtubePhase1` |

## YouTube Help note (retrieved 2026-11-09)

[YouTube Help — custom thumbnails](https://support.google.com/youtube/answer/72431?hl=en) currently recommends **3840 × 2160** for video thumbnails, JPG/PNG, 16:9, under device-dependent upload size limits. Phase 1 intentionally locks **1280×720** as the MVP verification profile (still a valid 16:9 YouTube-compatible size). A higher-resolution profile can be added later without changing the pipeline contract.
