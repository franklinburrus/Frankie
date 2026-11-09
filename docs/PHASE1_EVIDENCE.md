# Phase 1 acceptance evidence (template)

**Status: BLOCKED — no Mac worker / authorized-media run in this cloud session.**

## How to complete on Mac

```bash
Tools/run-phase1-acceptance.sh \
  --photo /path/to/authorized-participant.jpg \
  --ref /path/to/reference-example.jpg \
  --caption "EXACT CAPTION" \
  --style "match reference tone" \
  --out artifacts/phase1-acceptance
```

Then copy/replace this file with the generated `artifacts/phase1-acceptance/PHASE1_EVIDENCE.md` and complete the human checklist.

## Checklist

| Check | Result | Class |
|---|---|---|
| Export decodes | PENDING | UNKNOWN |
| Dimensions/format = 1280×720 JPEG/PNG | PENDING | UNKNOWN |
| Caption exact + readable | PENDING | UNKNOWN |
| Participants recognizable | PENDING | UNKNOWN |
| No invented quotes/events | PENDING | UNKNOWN |
| Source hashes unchanged | PENDING | UNKNOWN |
| Provenance recorded in sidecar | PENDING | UNKNOWN |
| Review state not READY unless human-validated | PENDING | UNKNOWN |

## Cloud substitute (not acceptance)

`python3 Tools/run-cloud-fixtures.py` exercises composite + caption + hash + dimensions on synthetic fixtures. That is **not** Phase 1 Done.
