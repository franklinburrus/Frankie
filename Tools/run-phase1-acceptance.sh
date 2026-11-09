#!/usr/bin/env bash
# Mac authorized-media Phase 1 acceptance runner.
# Usage:
#   Tools/run-phase1-acceptance.sh \
#     --photo /path/to/authorized1.jpg \
#     [--photo /path/to/authorized2.jpg] \
#     [--ref /path/to/example.jpg] \
#     --caption "EXACT CAPTION" \
#     [--style "style text"] \
#     [--out artifacts/phase1-acceptance]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  cat <<EOF
BLOCKED: Phase 1 authorized-media acceptance requires Frank's Mac.
This host is $(uname -s)/$(uname -m).

Next command on Mac (after authorized media paths are available):
  Tools/run-phase1-acceptance.sh --photo PATH --caption "TEXT" --out artifacts/phase1-acceptance

Evidence template: docs/PHASE1_EVIDENCE.md
EOF
  exit 2
fi

OUT="artifacts/phase1-acceptance"
PHOTOS=()
REFS=()
CAPTION=""
STYLE=""
PRESET="hero-left"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --photo) PHOTOS+=("$2"); shift 2 ;;
    --ref) REFS+=("$2"); shift 2 ;;
    --caption) CAPTION="$2"; shift 2 ;;
    --style) STYLE="$2"; shift 2 ;;
    --preset) PRESET="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ ${#PHOTOS[@]} -eq 0 || -z "$CAPTION" ]]; then
  echo "Requires --photo and --caption" >&2
  exit 2
fi

mkdir -p "$OUT"

echo "== baseline =="
EVIDENCE_CLASS=VERIFIED Tools/verify-mac-baseline.sh "$OUT/BASELINE.md"

echo "== inventory =="
Tools/inventory-image-stack.sh "$OUT/model-inventory.json" "$OUT/MODEL_INVENTORY.md"

echo "== build =="
swift build -c release

CLI=".build/release/frankie-cli"
ARGS=(generate --caption "$CAPTION" --style "$STYLE" --preset "$PRESET" --out "$OUT/export")
for p in "${PHOTOS[@]}"; do ARGS+=(--photo "$p"); done
for r in "${REFS[@]}"; do ARGS+=(--ref "$r"); done

echo "== generate =="
"$CLI" "${ARGS[@]}" | tee "$OUT/generate.txt"

# Re-hash sources to confirm unchanged.
echo "== source hashes after =="
for p in "${PHOTOS[@]}" "${REFS[@]:-}"; do
  [[ -n "${p:-}" ]] || continue
  "$CLI" hash "$p"
done | tee "$OUT/source-hashes-after.txt"

python3 - "$OUT" <<'PY'
from pathlib import Path
import json, datetime
out = Path(__import__("sys").argv[1])
export = out / "export"
sidecar = export / "job-record.json"
record = json.loads(sidecar.read_text()) if sidecar.exists() else {}
md = f"""# Phase 1 acceptance evidence

- Evidence class: `VERIFIED` (Mac run)
- Generated at: {datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')}
- Export dir: `{export}`
- Review state: `{record.get('reviewState')}`
- Generator: `{record.get('provenance', {}).get('generatorID')}`
- AI image generation claim: `{record.get('provenance', {}).get('isAIImageGeneration')}`
- Export SHA-256: `{record.get('exportSHA256')}`

## Checklist
- [ ] Export decodes
- [ ] Dimensions/format match Phase 1 profile (1280×720 JPEG/PNG)
- [ ] Caption exact and readable
- [ ] Participants recognizable
- [ ] No invented quotes/events
- [ ] Source hashes unchanged
- [ ] Provenance recorded
- [ ] Not marked READY unless human-validated

Fill remaining human inspection notes here.
"""
(out / "PHASE1_EVIDENCE.md").write_text(md)
print(f"Wrote {out / 'PHASE1_EVIDENCE.md'}")
PY

echo "DONE: fill human checklist in $OUT/PHASE1_EVIDENCE.md — do not mark READY until inspected."
