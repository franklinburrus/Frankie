# Decisions (repo mirror)

Thin mirror of [Frankie 03 — Decisions, Status and Next Action](https://docs.google.com/document/d/1SN7P7BOnbhmBWUdpW-TucuAVH368upxBNfNmdxnoHfE) plus Phase 1 implementation locks. Drive remains authoritative for D01–D09.

## Confirmed (Drive)

| ID | Summary |
|---|---|
| D01 | Native local Mac app; SwiftUI/macOS/Xcode SDK/AppKit proprietary boundary approved |
| D02 | First: real local thumbnail generation/editing with exact captions |
| D03 | Later: AI cartoon Shorts from authorized clips |
| D04 | Later Shorts: mute profanity before bleep; redact text; unknowns stay NEEDS REVIEW |
| D05 | Offline after approved setup; no cloud inference/paid APIs/telemetry/unauthorized uploads |
| D06 | Keep complete Caveman; do not import Joey app workflows |
| D07 | Delete Frankie application code only after Mac inventory; absence = NO-OP |
| D08 | Task 003B / large video-model install suspended; not a thumbnail gate |
| D09 | New installs/models require Frank approval; proposals are not approvals |

## Phase 1 implementation locks (this repo)

| Lock | Decision | Class |
|---|---|---|
| L1 | Pluggable `LocalImageGenerating` protocol | VERIFIED (code) |
| L2 | Discovery order: configured CLI → discovered tools → `DeterministicCompositeGenerator` | VERIFIED (code) |
| L3 | Composite path must set `isAIImageGeneration=false` | VERIFIED (code/tests) |
| L4 | Export profile Phase 1: **1280×720** JPEG/PNG (`youtube-phase1-1280x720`) | VERIFIED (code); see `EXPORT_PROFILE.md` |
| L5 | Pipeline never auto-marks `READY` | VERIFIED (code/tests) |
| L6 | Phase 2 Shorts deferred in README/STATUS | VERIFIED (docs) |

Related: `MODEL_DECISION.md`, Caveman reset notes in [Frankie 04](https://docs.google.com/document/d/17KdfHMVtnroTuDlQig8-aGi8sJWY29EoMVeoWHUA4lo), sources in [Frankie 05](https://docs.google.com/document/d/1DOQkgfJPrR8ac90mOHk54A0F75Fx5CPg5pOnWfCXWTA).
