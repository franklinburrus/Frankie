#!/usr/bin/env bash
# Inventory likely local image generation/editing stack on a Mac (or best-effort elsewhere).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT_JSON="${1:-docs/model-inventory.json}"
OUT_MD="${2:-docs/MODEL_INVENTORY.md}"
HOST="$(uname -s)"
ARCH="$(uname -m)"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HOME_DIR="${HOME:-}"
FFMPEG_PATH="$(command -v ffmpeg || true)"

candidates=(
  "diffusionbee|${HOME_DIR}/Applications/DiffusionBee.app"
  "draw-things|${HOME_DIR}/Applications/Draw Things.app"
  "automatic1111|${HOME_DIR}/stable-diffusion-webui"
  "comfyui|${HOME_DIR}/ComfyUI"
  "mlx|${HOME_DIR}/mlx-examples"
  "coreml-models|${HOME_DIR}/Models"
  "ollama|/usr/local/bin/ollama"
  "ollama-homebrew|/opt/homebrew/bin/ollama"
  "ffmpeg|/usr/local/bin/ffmpeg"
  "ffmpeg-homebrew|/opt/homebrew/bin/ffmpeg"
  "ffmpeg-path|${FFMPEG_PATH}"
)

found_json="["
first=1
found_md=""
for entry in "${candidates[@]}"; do
  id="${entry%%|*}"
  path="${entry#*|}"
  present=false
  if [[ -n "$path" && -e "$path" ]]; then
    present=true
  fi
  if [[ $first -eq 1 ]]; then
    first=0
  else
    found_json+=","
  fi
  # JSON-escape path via python for spaces/quotes.
  path_json="$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$path")"
  found_json+=$(printf '{"id":"%s","path":%s,"present":%s}' "$id" "$path_json" "$present")
  found_md+="- ${id}: present=${present} path=${path}"$'\n'
done
found_json+="]"

fonts_note="UNKNOWN"
coreml_note="UNKNOWN"
if [[ "$HOST" == "Darwin" ]]; then
  if [[ -d /Library/Fonts || -d "$HOME_DIR/Library/Fonts" ]]; then
    fonts_note="System/user font directories present (individual licence check still required)"
  fi
  scan_roots=()
  [[ -d "$HOME_DIR/Library/Application Support" ]] && scan_roots+=("$HOME_DIR/Library/Application Support")
  [[ -d "$HOME_DIR/Models" ]] && scan_roots+=("$HOME_DIR/Models")
  [[ -d /opt ]] && scan_roots+=("/opt")
  if [[ ${#scan_roots[@]} -gt 0 ]]; then
    coreml_count="$(find "${scan_roots[@]}" \( -name '*.mlmodelc' -o -name '*.mlpackage' \) 2>/dev/null | head -n 20 | wc -l | tr -d ' ' || true)"
  else
    coreml_count=0
  fi
  coreml_note="Sample scan hit count (bounded): ${coreml_count}"
fi

evidence="REPORTED"
if [[ "$HOST" == "Darwin" ]]; then
  evidence="VERIFIED"
elif [[ "$HOST" != "Darwin" ]]; then
  evidence="VERIFIED (cloud host only; Mac models UNKNOWN)"
fi

mkdir -p "$(dirname "$OUT_JSON")" "$(dirname "$OUT_MD")"
python3 - "$OUT_JSON" "$HOST" "$ARCH" "$STAMP" "$evidence" "$found_json" "$fonts_note" "$coreml_note" <<'PY'
import json,sys
out, host, arch, stamp, evidence, found_json, fonts, coreml = sys.argv[1:9]
doc = {
  "generated_at": stamp,
  "host": host,
  "arch": arch,
  "evidence_class": evidence,
  "candidates": json.loads(found_json),
  "fonts_note": fonts,
  "coreml_note": coreml,
}
open(out,"w").write(json.dumps(doc, indent=2) + "\n")
PY

{
  echo "# Frankie model inventory"
  echo
  echo "- Evidence class: \`${evidence}\`"
  echo "- Generated at: \`${STAMP}\`"
  echo "- Host: \`${HOST}\` / \`${ARCH}\`"
  echo
  echo "## Candidates"
  echo
  printf '%s\n' "$found_md"
  echo "## Notes"
  echo
  echo "- Fonts: ${fonts_note}"
  echo "- Core ML scan: ${coreml_note}"
  if [[ "$HOST" == "Darwin" ]]; then
    echo "- Candidate scan completed on Frank's Mac. Present tools are listed above; absent generative runners mean Phase 1 continues on composite fallback unless Frank approves an install (D09)."
  else
    echo "- Mac-installed generative image models remain **UNKNOWN** until this script is run on Frank's Mac."
  fi
  echo "- No installs performed (D09)."
  echo
  echo "Machine-readable: \`${OUT_JSON}\`"
} >"$OUT_MD"

echo "Wrote $OUT_JSON and $OUT_MD"
