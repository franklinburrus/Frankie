# Frankie baseline evidence

- Evidence class: `VERIFIED`
- Generated at: 2026-11-09T20:00:03Z
- Host: Linux x86_64
- Repo root: `/agent/repos/Frankie`
- Origin: `https://github.com/franklinburrus/Frankie`
- Branch: `cursor/phase1-thumbnail-mvp-0525`
- HEAD: `32c9161ddfac6e34c299aa412a889a6494dcf2f6`

## Origin check
- Origin matches Frankie: YES

## Protected Caveman paths

| Path | Present | git blob SHA-1 | Matches provenance |
|---|---|---|---|
| `AGENTS.md` | YES | `a6d466866855bb8cdff7abe70226119776981e90` | Frankie-specific (not Joey copy) |
| `.agents/skills/caveman/SKILL.md` | YES | `9a94044529e5ee1576361c891b4a271504518e6f` | YES |
| `.agents/skills/ultracave/SKILL.md` | YES | `136db7e5c8804043c5329df8f767789b7d30228f` | YES |
| `third_party/caveman/LICENSE` | YES | `d645695673349e3947e8e5ae42332d0ac3164cd7` | YES |
| `third_party/caveman/LICENSE-MIT` | YES | `d8c0ee8a752aeb14ee42044c3238e191f7571ac6` | YES |
| `third_party/caveman/NOTICE` | YES | `5b6c03199300662964c1c27906d9bdff47349e26` | YES |
| `third_party/caveman/provenance.json` | YES | `b3a42bbfc9decd44196794faaea52f37982eb5cb` | present (records other file hashes) |

## App-code presence

- Application-related paths present: 18

```
Frankie/App/ContentView.swift
Frankie/App/FrankieApp.swift
Frankie/App/Frankie.entitlements
Frankie/App/ThumbnailJobViewModel.swift
Frankie/Core/CaptionOverlay.swift
Frankie/Core/DeterministicCompositeGenerator.swift
Frankie/Core/ExportProfile.swift
Frankie/Core/FileHash.swift
Frankie/Core/JobRecord.swift
Frankie/Core/LayoutPresets.swift
Frankie/Core/LocalImageGenerating.swift
Frankie/Core/Models.swift
Frankie/Core/PNGCodec.swift
Frankie/Core/ThumbnailPipeline.swift
Frankie.xcodeproj/project.pbxproj
Package.swift
Tests/FrankieCoreTests/FrankieCoreTests.swift
Tools/FrankieCLI/main.swift
```

- Pre-Phase-1 GitHub/cloud empty shell had no app code: VERIFIED NO-OP for deletion.
- This checkout now contains Phase 1 scaffold (expected after implementation).

## Result
- Caveman seven-path integrity: PASS
